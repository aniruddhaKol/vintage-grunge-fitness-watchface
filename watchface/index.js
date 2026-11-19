import hmUI from '@zos/ui'
import { getScene, SCENE_AOD } from '@zos/app'
import { Battery, Calorie, Vibrator, VIBRATOR_SCENE_SHORT_MIDDLE } from '@zos/sensor'
import {
  launchApp, SYSTEM_APP_HR, SYSTEM_APP_SPO2,
  SYSTEM_APP_WEATHER, SYSTEM_APP_CALENDAR,
  SYSTEM_APP_ALARM, SYSTEM_APP_COUNTDOWN, SYSTEM_APP_STOPWATCH
} from '@zos/router'

const digits = name => Array.from({ length: 10 }, (_, i) => `${name}-${i}.png`)
// IMG_LEVEL counts frames from 1, including the empty 0% frame.
const batteryFrameLevel = charge => charge + 1
const batteryIconSource = charge => {
  if (charge < 20) return 'battery-icon-red.png'
  if (charge <= 50) return 'battery-icon-amber.png'
  return 'battery-icon-green.png'
}
const normal = hmUI.show_level.ONLY_NORMAL
WatchFace({
  build() {
    this.initView()
  },
  initView() {
    if (getScene() === SCENE_AOD) this.buildAod()
    else this.buildNormal()
  },
  buildNormal() {
    hmUI.createWidget(hmUI.widget.IMG, { x: 0, y: 0, src: 'background.png', show_level: normal })
    hmUI.createWidget(hmUI.widget.IMG_TIME, {
      hour_startX: 53, hour_startY: 161, hour_array: digits('time'), hour_space: 14, hour_zero: 1,
      minute_startX: 192, minute_startY: 161, minute_array: digits('time'), minute_space: 16, minute_zero: 1, minute_follow: 0,
      second_startX: 325, second_startY: 166, second_array: digits('seconds'), second_space: 0, second_zero: 1, second_follow: 0,
      show_level: normal
    })
    const number = (type,x,y,w,h,font,extra={}) => hmUI.createWidget(hmUI.widget.TEXT_IMG, {
      x,y,w,h,type,font_array: digits(font),h_space: 0,align_h: hmUI.align.CENTER_H,show_level:normal,...extra
    })
    number(hmUI.data_type.HEART,62,65,75,44,'health')
    number(hmUI.data_type.SPO2,194,65,75,44,'health')
    // Five-digit calories switch to smaller digits so the whole number fits the panel.
    const calLarge = number(hmUI.data_type.CAL,327,65,78,44,'cal')
    const calSmall = number(hmUI.data_type.CAL,327,74,78,35,'cal-small')
    this.calorie = new Calorie()
    this.updateCalorie = () => {
      const fiveDigits = this.calorie.getCurrent() >= 10000
      calLarge.setProperty(hmUI.prop.VISIBLE,!fiveDigits)
      calSmall.setProperty(hmUI.prop.VISIBLE,fiveDigits)
    }
    this.updateCalorie()
    this.calorie.onChange(this.updateCalorie)
    number(hmUI.data_type.SUN_RISE,134,296,65,27,'small',{dot_image:'colon.png'})
    number(hmUI.data_type.SUN_SET,229,296,65,27,'small',{dot_image:'colon.png'})
    number(hmUI.data_type.WEATHER_CURRENT,350,270,62,35,'temp',{negative_image:'minus.png',unit_en:'degree.png',unit_sc:'degree.png',unit_tc:'degree.png'})
    number(hmUI.data_type.STEP,82,381,124,42,'activity')
    number(hmUI.data_type.DISTANCE,279,381,132,42,'distance',{dot_image:'dot.png',unit_en:'km.png',unit_sc:'km.png',unit_tc:'km.png',imperial_unit_en:'mi.png',imperial_unit_sc:'mi.png',imperial_unit_tc:'mi.png'})
    const week = Array.from({length:7},(_,i)=>`week-${i}.png`)
    hmUI.createWidget(hmUI.widget.IMG_WEEK,{x:27,y:271,week_en:week,week_sc:week,week_tc:week,show_level:normal})
    const day = digits('small')
    const month = Array.from({ length: 12 }, (_, i) => `month-${i}.png`)
    hmUI.createWidget(hmUI.widget.IMG_DATE,{
      month_startX:36,month_startY:300,month_en_array:month,month_sc_array:month,month_tc_array:month,
      month_is_character:true,month_follow:0,month_align:hmUI.align.LEFT,
      day_startX:80,day_startY:271,day_en_array:day,day_sc_array:day,day_tc_array:day,
      day_zero:1,day_space:0,day_align:hmUI.align.LEFT,show_level:normal
    })
    this.battery = new Battery()
    const readCharge = () => Math.max(0,Math.min(100,this.battery.getCurrent()))
    const charge = readCharge()
    const batteryBar = hmUI.createWidget(hmUI.widget.IMG_LEVEL,{
      x:89,y:456,image_array:Array.from({length:101},(_,i)=>`battery-level-${i}.png`),
      image_length:101,level:batteryFrameLevel(charge),show_level:normal
    })
    const iconLayout = {x:50,y:441,w:20,h:39}
    const batteryIcon = hmUI.createWidget(hmUI.widget.IMG,{
      ...iconLayout,src:batteryIconSource(charge),show_level:normal
    })
    this.updateBattery = () => {
      const currentCharge = readCharge()
      batteryBar.setProperty(hmUI.prop.LEVEL,batteryFrameLevel(currentCharge))
      batteryIcon.setProperty(hmUI.prop.MORE,{...iconLayout,src:batteryIconSource(currentCharge)})
    }
    this.battery.onChange(this.updateBattery)
    this.highlights = []
    hmUI.createWidget(hmUI.widget.WIDGET_DELEGATE,{resume_call:() => {
      this.updateBattery()
      this.updateCalorie()
      this.highlights.forEach(w => w.setProperty(hmUI.prop.VISIBLE,false))
    }})
    number(hmUI.data_type.BATTERY,345,451,56,29,'battery',{unit_en:'percent.png',unit_sc:'percent.png',unit_tc:'percent.png'})
    hmUI.createWidget(hmUI.widget.IMG,{x:0,y:0,src:'rounded-corners.png',show_level:normal})
    this.vibration = new Vibrator()
    const highlight = (x,y,w,h,color) => {
      const image = hmUI.createWidget(hmUI.widget.IMG,{x,y,src:`press-${color}-${w}x${h}.png`,show_level:normal})
      image.setProperty(hmUI.prop.VISIBLE,false)
      this.highlights.push(image)
      return image
    }
    const pulse = () => {
      this.vibration.stop()
      this.vibration.start({mode:VIBRATOR_SCENE_SHORT_MIDDLE})
    }
    const tap = (x,y,w,h,appId,color) => {
      const glow = highlight(x,y,w,h,color)
      return hmUI.createWidget(hmUI.widget.BUTTON,{
      x,y,w,h,text:'',normal_src:`tap-${w}x${h}.png`,press_src:`press-${color}-${w}x${h}.png`,show_level:normal,
      click_func:() => {
        if(this.navigationTimer != null) return
        pulse()
        glow.setProperty(hmUI.prop.VISIBLE,true)
        // Keep feedback briefly visible after release before opening the destination.
        this.navigationTimer = setTimeout(() => {
          this.navigationTimer = null
          this.vibration.stop()
          glow.setProperty(hmUI.prop.VISIBLE,false)
          launchApp({appId,native:true})
        },180)
      }
    })
    }
    const metricTap = (x,y,w,h,type,color) => {
      const glow = highlight(x,y,w,h,color)
      // Native metric shortcuts retain the OS's section-specific routing.
      const hit = hmUI.createWidget(hmUI.widget.IMG_CLICK,{x,y,w,h,src:`tap-${w}x${h}.png`,type,show_level:normal})
      hit.addEventListener(hmUI.event.CLICK_DOWN,() => {pulse();glow.setProperty(hmUI.prop.VISIBLE,true)})
      hit.addEventListener(hmUI.event.CLICK_UP,() => glow.setProperty(hmUI.prop.VISIBLE,false))
      return hit
    }
    tap(16,35,132,77,SYSTEM_APP_HR,'red')
    tap(148,35,135,77,SYSTEM_APP_SPO2,'blue')
    metricTap(283,35,133,77,hmUI.data_type.CAL,'orange')
    tap(16,118,161,132,SYSTEM_APP_ALARM,'cream')
    tap(177,118,133,132,SYSTEM_APP_COUNTDOWN,'cream')
    tap(310,118,106,132,SYSTEM_APP_STOPWATCH,'red')
    tap(16,256,104,86,SYSTEM_APP_CALENDAR,'blue')
    metricTap(120,256,96,86,hmUI.data_type.SUN_RISE,'amber')
    metricTap(216,256,96,86,hmUI.data_type.SUN_SET,'red')
    tap(312,256,104,86,SYSTEM_APP_WEATHER,'orange')
    metricTap(16,348,200,83,hmUI.data_type.STEP,'green')
    metricTap(216,348,200,83,hmUI.data_type.DISTANCE,'blue')
    metricTap(16,436,400,62,hmUI.data_type.BATTERY,'green')
  },
  buildAod() {
    hmUI.createWidget(hmUI.widget.FILL_RECT,{x:0,y:0,w:432,h:514,color:0x000000})
    const aod = hmUI.show_level.ONAL_AOD
    hmUI.createWidget(hmUI.widget.IMG,{x:0,y:0,src:'aod-background.png',show_level:aod})
    // Match the supplied industrial reference, with live readings and no seconds.
    hmUI.createWidget(hmUI.widget.IMG_TIME,{
      hour_startX:46,hour_startY:91,hour_array:digits('aod-clock'),hour_space:29,hour_zero:1,
      minute_startX:237,minute_startY:91,minute_array:digits('aod-clock'),minute_space:29,minute_zero:1,minute_follow:0,
      show_level:aod
    })
    const aodWeek = Array.from({length:7},(_,i)=>`aod-large-week-${i}.png`)
    hmUI.createWidget(hmUI.widget.IMG_WEEK,{x:113,y:254,week_en:aodWeek,week_sc:aodWeek,week_tc:aodWeek,show_level:aod})
    hmUI.createWidget(hmUI.widget.IMG_DATE,{
      day_startX:238,day_startY:254,day_en_array:digits('aod-date'),day_sc_array:digits('aod-date'),day_tc_array:digits('aod-date'),
      day_zero:1,day_space:0,day_align:hmUI.align.LEFT,show_level:aod
    })
    hmUI.createWidget(hmUI.widget.IMG,{x:97,y:334,src:'aod-steps-label.png',show_level:aod})
    hmUI.createWidget(hmUI.widget.TEXT_IMG,{x:74,y:357,w:139,h:45,type:hmUI.data_type.STEP,font_array:digits('aod-activity'),align_h:hmUI.align.CENTER_H,show_level:aod})
    hmUI.createWidget(hmUI.widget.IMG,{x:285,y:334,src:'aod-distance-label.png',show_level:aod})
    hmUI.createWidget(hmUI.widget.TEXT_IMG,{x:275,y:357,w:136,h:45,type:hmUI.data_type.DISTANCE,font_array:digits('aod-distance'),dot_image:'aod-dot.png',unit_en:'aod-km.png',unit_sc:'aod-km.png',unit_tc:'aod-km.png',imperial_unit_en:'aod-mi.png',imperial_unit_sc:'aod-mi.png',imperial_unit_tc:'aod-mi.png',align_h:hmUI.align.CENTER_H,show_level:aod})
    this.battery = new Battery()
    const readCharge = () => Math.max(0,Math.min(100,this.battery.getCurrent()))
    const charge = readCharge()
    const batteryBar = hmUI.createWidget(hmUI.widget.IMG_LEVEL,{
      x:85,y:448,image_array:Array.from({length:101},(_,i)=>`aod-battery-level-${i}.png`),
      image_length:101,level:batteryFrameLevel(charge),show_level:aod
    })
    const iconLayout = {x:50,y:434,w:20,h:39}
    const iconSource = charge => `aod-${batteryIconSource(charge)}`
    const batteryIcon = hmUI.createWidget(hmUI.widget.IMG,{
      ...iconLayout,src:iconSource(charge),show_level:aod
    })
    this.updateBattery = () => {
      const currentCharge = readCharge()
      batteryBar.setProperty(hmUI.prop.LEVEL,batteryFrameLevel(currentCharge))
      batteryIcon.setProperty(hmUI.prop.MORE,{...iconLayout,src:iconSource(currentCharge)})
    }
    this.battery.onChange(this.updateBattery)
    hmUI.createWidget(hmUI.widget.WIDGET_DELEGATE,{resume_call:() => this.updateBattery()})
    hmUI.createWidget(hmUI.widget.TEXT_IMG,{
      x:343,y:442,w:60,h:30,type:hmUI.data_type.BATTERY,font_array:digits('aod-bat'),
      unit_en:'aod-bat-percent.png',unit_sc:'aod-bat-percent.png',unit_tc:'aod-bat-percent.png',
      align_h:hmUI.align.CENTER_H,show_level:aod
    })
    hmUI.createWidget(hmUI.widget.IMG,{x:0,y:0,src:'rounded-corners.png',show_level:aod})
  },
  onInit() {},
  onDestroy() {
    if(this.highlights) this.highlights.forEach(w => w.setProperty(hmUI.prop.VISIBLE,false))
    if(this.navigationTimer != null) {
      clearTimeout(this.navigationTimer)
      this.navigationTimer = null
    }
    if(this.vibration) this.vibration.stop()
    if(this.battery && this.updateBattery) this.battery.offChange(this.updateBattery)
    if(this.calorie && this.updateCalorie) this.calorie.offChange(this.updateCalorie)
  }
})
