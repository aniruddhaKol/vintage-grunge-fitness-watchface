const projectRoot = require('path').resolve(__dirname, '..')
process.chdir(projectRoot)
const fs = require('fs')
const vm = require('vm')
const widgets = []
const names = new Proxy({}, {get:(_,key)=>key})
const source = fs.readFileSync('watchface/index.js','utf8')
const importMatch = source.match(/import\s*\{([^{}]*)\}\s*from '@zos\/router'/)
const routeNames = importMatch[1].split(',').map(s=>s.trim()).filter(s=>s!=='launchApp')
const calls = []
let pendingNavigation
let faceInstance
const showLevel=process.argv.includes('--aod')?2:1
if(/hmSensor|timer\.createTimer|ONLY_AOD/.test(source))throw new Error('Legacy globals or invalid AOD constant remain')
if(!source.includes("import hmUI from '@zos/ui'"))throw new Error('Missing UI module import')
vm.runInNewContext(source.replace(/import\s+(?:\w+\s+from|\{[^{}]*\}\s*from)\s*'[^']+'\s*/g,''), {
  ...Object.fromEntries(routeNames.map(s=>[s,s])),
  launchApp:options=>calls.push(['launch',options.appId,options.native]),
  getScene:()=>showLevel,SCENE_AOD:2,
  setTimeout:(callback,delay)=>{if(delay!==180)throw new Error('Expected short highlight delay');pendingNavigation=callback;return 1},clearTimeout:()=>{pendingNavigation=null},
  Battery:class {getCurrent(){return 49}onChange(){}offChange(){}},
  Vibrator:class {stop(){calls.push(['stop','VIBRATE'])}start(options){calls.push(['start','VIBRATE',options.mode])}},VIBRATOR_SCENE_SHORT_MIDDLE:24,
  hmUI:{widget:names,data_type:names,prop:names,event:names,show_level:{ONLY_NORMAL:1,ONAL_AOD:2},align:{LEFT:0,CENTER_H:1},createWidget:(kind,props)=>{
    if(props.show_level!==undefined && props.show_level!==showLevel)throw new Error('Created widget for the wrong scene')
    if(props.show_level===undefined && kind!=='FILL_RECT' && kind!=='WIDGET_DELEGATE')throw new Error('Missing display level')
    const record={kind,...props,events:{}}
    widgets.push(record);return {setProperty:(key,value)=>{if(key==='VISIBLE')record.visible=value},addEventListener:(key,callback)=>{record.events[key]=callback}}
  }},
  WatchFace:face=>{faceInstance=face;face.build()}
})
const taps=widgets.filter(w=>w.kind==='BUTTON' || w.kind==='IMG_CLICK')
if(taps.length!==(showLevel===1?13:0)) throw new Error('Incorrect clickable sections for scene')
for(let i=0;i<taps.length;i++) {
  const tap=taps[i]
  if(tap.show_level!==1) throw new Error('Touch zone enabled in AOD')
  for(const other of taps.slice(i+1)) {
    if(tap.x<other.x+other.w && tap.x+tap.w>other.x && tap.y<other.y+other.h && tap.y+tap.h>other.y) throw new Error('Overlapping touch zones')
  }
  calls.length=0
  if(tap.kind==='IMG_CLICK') {
    if(!['CAL','STEP','DISTANCE','SPO2','BATTERY','SUN_RISE','SUN_SET'].includes(tap.type))throw new Error('Incorrect native metric route')
    tap.events.CLICK_DOWN()
    const active=widgets.filter(w=>w.src && w.src.startsWith('press-') && w.visible===true)
    if(active.length!==1 || active[0].x!==tap.x || active[0].y!==tap.y)throw new Error('Highlight spills into another section')
    if(calls[1][0]!=='start')throw new Error('Metric shortcut missing vibration')
    if(calls.some(c=>c[0]==='launch'))throw new Error('Metric uses generic app route')
    tap.events.CLICK_UP()
    continue
  }
  tap.click_func()
  const active=widgets.filter(w=>w.src && w.src.startsWith('press-') && w.visible===true)
  if(active.length!==1 || active[0].x!==tap.x || active[0].y!==tap.y)throw new Error('Button highlight missing or spills into another section')
  if(calls.some(c=>c[0]==='launch')) throw new Error('Navigation interrupts vibration')
  tap.click_func()
  if(calls.length!==2)throw new Error('Rapid taps were not debounced')
  pendingNavigation()
  if(JSON.stringify(calls.slice(0,2))!==JSON.stringify([['stop','VIBRATE'],['start','VIBRATE',24]]) || calls[3][0]!=='launch' || calls[3][2]!==true) throw new Error('Missing haptic feedback before navigation')
  for(const filename of [tap.normal_src,tap.press_src]) if(!fs.existsSync('assets/432x514-amazfit-bip-max/'+filename)) throw new Error('Missing touch asset')
}
calls.length=0
if(showLevel===1) {
  for(const type of ['BATTERY','SUN_RISE','SUN_SET']) if(!taps.some(w=>w.kind==='IMG_CLICK' && w.type===type))throw new Error('Missing native '+type+' shortcut')
  const oxygen=taps.find(w=>w.x===148&&w.y===35)
  if(!oxygen||oxygen.kind!=='BUTTON')throw new Error('SpO2 must use an explicit app shortcut')
  oxygen.click_func();pendingNavigation()
  if(!calls.some(c=>c[0]==='launch'&&c[1]==='SYSTEM_APP_SPO2'&&c[2]===true))throw new Error('Wrong SpO2 destination')
  calls.length=0
  const date=taps.find(w=>w.x===16 && w.y===256)
  if(date.press_src!=='press-blue-104x86.png')throw new Error('Date highlight must contrast with cream background')
}
if(taps.length)taps[0].click_func()
faceInstance.onDestroy()
if(taps.length && pendingNavigation!==null)throw new Error('Navigation was not cancelled on destroy')
if(taps.length && !calls.some(c=>c[0]==='stop' && c[1]==='VIBRATE')) throw new Error('Vibration was not stopped on destroy')
const values = { HEART:'78',SPO2:'98',CAL:'174',SUN_RISE:'06.12',SUN_SET:'18.09',WEATHER_CURRENT:'29u',STEP:'5204',DISTANCE:'3.24u',BATTERY:'49u' }
const draw=[]
const assetRoot='assets/432x514-amazfit-bip-max/'
const size=file=>{
  const data=fs.readFileSync(assetRoot+file)
  return [data.readUInt32BE(16),data.readUInt32BE(20)]
}
const add=(src,x,y)=>{size(src);draw.push({src,x,y})}
if(showLevel===1 && process.argv.includes('--tap-distance')) {
  widgets.find(w=>w.kind==='IMG_CLICK' && w.type==='DISTANCE').events.CLICK_DOWN()
}
if(showLevel===1 && process.argv.includes('--tap-date')) widgets.find(w=>w.kind==='BUTTON' && w.x===16 && w.y===256).click_func()
for(const w of widgets.filter(w=>w.show_level===showLevel && w.visible!==false)) {
  if(w.kind==='IMG')add(w.src,w.x,w.y)
  if(w.kind==='IMG_TIME')for(const [prefix,value] of [['hour','05'],['minute','26'],['second','08']]) {
    if(!w[prefix+'_array'])continue
    let x=w[prefix+'_startX'];const y=w[prefix+'_startY']
    for(const c of value){const src=w[prefix+'_array'][+c];add(src,x,y);x+=size(src)[0]+w[prefix+'_space']}
  }
  if(w.kind==='TEXT_IMG') {
    const files=[...values[w.type]].map(c=>c==='u'?w.unit_en:c==='.'?w.dot_image:w.font_array[+c])
    const width=files.reduce((n,f)=>n+size(f)[0],0)
    let x=w.x+(w.align_h===0?0:Math.floor((w.w-width)/2))
    for(const f of files){add(f,x,w.y);x+=size(f)[0]}
  }
  if(w.kind==='IMG_WEEK')add(w.week_en[Number(process.argv.find(a=>a.startsWith('--weekday='))?.split('=')[1] ?? 1)],w.x,w.y)
  if(w.kind==='IMG_DATE'){add(w.day_en_array[2],w.day_startX,w.day_startY);add(w.day_en_array[9],w.day_startX+size(w.day_en_array[2])[0],w.day_startY)}
  if(w.kind==='IMG_LEVEL')add(w.image_array[49],w.x,w.y)
}
fs.writeFileSync('previews/preview-layout.json',JSON.stringify(draw))
if(!draw.length)throw new Error('Black screen: no visible assets')
console.log(`Validated ${widgets.length} widgets, ${taps.length} tap zones, scene-specific initialization and ${draw.length} preview images (${showLevel===2?'AOD':'normal'}).`)
