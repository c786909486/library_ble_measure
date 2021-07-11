library library_ble_measure;

import 'dart:math';

import 'package:flutter_blue/flutter_blue.dart';
import 'package:library_ble_measure/model/blood_sugar_model.dart';
import 'package:library_ble_measure/model/tem_model.dart';
import 'package:library_ble_measure/model/yuwell_pressure_model.dart';
import 'package:library_ble_measure/utils/ext.dart';

typedef Future<dynamic> EventHandlerMap<T>(T event);

class BleMeasurePlugin {
  FlutterBlue _flutterBlue;
  List<BluetoothDevice> linkDevices = [];

  BleMeasurePlugin._() {
    _flutterBlue = FlutterBlue.instance;
  }

  ///体温设备
  BluetoothDevice temDevice;
  BluetoothCharacteristic temService;
  BluetoothDeviceState temDeviceState;
  var temServiceUuid = "0000fec8-feba-f1f1-99c0-7e0ce07d0c03";

  static BleMeasurePlugin _instance = new BleMeasurePlugin._();

  static BleMeasurePlugin get instance => _instance;

  ///连接家测宝
  void connectTemDevice(BluetoothDevice devices) async {
    await devices.connect(autoConnect: true);
    devices.state.listen((event) async {
      if (temDevice != null) {
        linkDevices.remove(temDevice);
      }
      temDevice = devices;
      linkDevices.add(temDevice);
      var state = BluetoothDeviceState.values[event.index];
      temDeviceState = state;
      if (_temStateHandler != null) {
        _temStateHandler(state);
      }
      if (state == BluetoothDeviceState.connected) {
        var discoverServices = await devices.discoverServices();
        Future.delayed(Duration(milliseconds: 200), () {
          discoverServices.forEach((element) {
            element.characteristics.forEach((cha) {
              var chaUUid = cha.uuid.toString();
              if (chaUUid == temServiceUuid) {
                temService = cha;
                temService.setNotifyValue(true);
                temService.value.listen((event) {
                  var va16 = event.map((e) {
                    var data = e.toRadixString(16).toUpperCase();
                    if (data.length == 1) {
                      data = "0$data";
                    }
                    return data;
                  }).toList();
                  if (va16.isNotEmpty) {
                    var map = Map();

                    ///获取当前测量类型 00测量模式 其他为记忆组数
                    ///第2，第3字节：记忆数据，3030，表示记值为00，3031，表示记值为01，可以表示00-99，共50组记忆值，当为测量模式时，固定为30 30
                    map["measureStatus"] =
                        va16[1].substring(1) + va16[2].substring(1);

                    ///状态码30，表示状态码为0号，可以表示0-9，共10个状态
                    /// 30：回传测量人体温度值
                    /// 31：回传测量表面温度值
                    /// 32：回传记忆人体温度
                    /// 33：回传记忆表面温度
                    /// 34：回传测量耳温温度值
                    /// 35：回传环境温度值
                    /// 36-39 待定备用
                    map["measureType"] = va16[3];

                    var firstValue = va16[4];
                    var temValue = list2Str(va16.sublist(5, 9));
                    var error = "";
                    print("temValue==>${temValue}");
                    switch (temValue) {
                      case "54 61 4C 6F":
                        error = "环境温度低于0.1°C";
                        if (_temErrorHandler != null) {
                          _temErrorHandler(error);
                        }
                        break;
                      case "54 61 48 69":
                        error = "环境温度高于40°C";
                        if (_temErrorHandler != null) {
                          _temErrorHandler(error);
                        }
                        break;
                      case "54 62 4C 6F":
                        error =
                            firstValue == "31" ? "目标温度低于0.1°C" : "目标温度低于32°C";
                        if (_temErrorHandler != null) {
                          _temErrorHandler(error);
                        }
                        break;
                      case "54 62 48 69":
                        error =
                            firstValue == "31" ? "目标温度高于100°C" : "目标温度高于43°C";
                        if (_temErrorHandler != null) {
                          _temErrorHandler(error);
                        }
                        break;
                      case "45 72 2E 72":
                        error = "系统自检错误";
                        if (_temErrorHandler != null) {
                          _temErrorHandler(error);
                        }
                        break;
                      case "45 72 2E 45":
                        error = "读EPPOM错误";
                        if (_temErrorHandler != null) {
                          _temErrorHandler(error);
                        }
                        break;
                      default:
                        var temList = va16.sublist(5, 9);
                        var tem = temList[0].substring(1) +
                            temList[1].substring(1) +
                            "." +
                            temList[3].substring(1);
                        map["temValue"] = tem;
                        if (_temHandler != null) {
                          _temHandler(TemModel.fromJson(map));
                        }
                        break;
                    }

                    print(va16);
                  }
                });
              }
            });
          });
        });
      }
    });
  }

  ///家测宝回调
  EventHandlerMap<TemModel> _temHandler;
  EventHandlerMap<String> _temErrorHandler;

  void addTemMeasureListener(
      {EventHandlerMap<TemModel> temHandeler,
      EventHandlerMap<String> temErrorHandler}) {
    this._temHandler = temHandeler;

    this._temErrorHandler = temErrorHandler;
  }

  ///添加血压仪监听
  EventHandlerMap<String> _pressureMeasuringHandler;
  EventHandlerMap<YuwellPressureModel> _pressureResultHandler;
  BluetoothDeviceState _yuwellPressureState = BluetoothDeviceState.disconnected;

  void addPressureMeasureListener(
      {EventHandlerMap<String> pressureMeasuringHandler,
      EventHandlerMap<YuwellPressureModel> pressureResultHandler}) {
    this._pressureMeasuringHandler = pressureMeasuringHandler;
    this._pressureResultHandler = pressureResultHandler;
  }

  ///设备连接监听
  EventHandlerMap<BluetoothDeviceState> _temStateHandler;
  EventHandlerMap<BluetoothDeviceState> _pressureStateHandler;
  EventHandlerMap<BluetoothDeviceState> _bloodStateHandler;

  void addDeviceStateListener(
      {EventHandlerMap<BluetoothDeviceState> pressureStateHandler,
      EventHandlerMap<BluetoothDeviceState> temStateHandler,
      EventHandlerMap<BluetoothDeviceState> bloodStateHandler}) {
    this._pressureStateHandler = pressureStateHandler;
    this._temStateHandler = temStateHandler;
    this._bloodStateHandler = bloodStateHandler;
  }

  void temDeviceDisconnect() {
    if (temDevice != null) {
      temDevice.disconnect();
    }
    temDeviceState = BluetoothDeviceState.disconnected;
    temDevice = null;
    temService = null;
  }

  String list2Str(List<String> strs) {
    String str = "";
    for (var item in strs) {
      str += " ${item}";
    }
    return str;
  }

  ///鱼跃血压计设备
  BluetoothDevice _yuyuePresureDevice;
  BluetoothCharacteristic _yuyuePressureMeasureService;
  BluetoothCharacteristic _yuyuePressureResultService;
  BluetoothDeviceState yuyuePressureDeviceState;

  ///鱼跃血压仪设备uuid
  var _yuyuePressureServiceUUid = "00001810-0000-1000-8000-00805f9b34fb";

  ///血压测量结果uuid
  var _yuyuePressureResultUUid = "00002a35-0000-1000-8000-00805f9b34fb";

  ///袖带实时测量结果
  var _yuyuePressureMeasureUUid = "00002a36-0000-1000-8000-00805f9b34fb";
  var _yuwellConnect = false;

  ///连接鱼跃血压仪
  void connectYuyuePresure(BluetoothDevice device) async {
    if (_yuwellConnect) {
      return;
    }
    _yuyuePresureDevice = device;
    _yuyuePresureDevice.state.listen((event) async {
      if (event != BluetoothDeviceState.connected &&
          event != BluetoothDeviceState.connecting) {
        print("开始连接======>");
        _yuwellConnect = true;
        await _yuyuePresureDevice.connect();
      } else {
        _yuwellConnect = false;
      }
      print("yuyuePressureConnectStatus===>${event}");
      if (_yuyuePresureDevice != null) {
        linkDevices.remove(_yuyuePresureDevice);
      }

      linkDevices.add(_yuyuePresureDevice);

      if (event == BluetoothDeviceState.connected) {
        var discoverServices = await device.discoverServices();
        // print("连接设备数量：${linkDevices.length}");
        // print(discoverServices.toString());
        discoverServices.forEach((element) {
          if (element.uuid.toString() == _yuyuePressureServiceUUid) {
            element.characteristics.forEach((element) async {
              var chaUuid = element.uuid.toString();
              if (chaUuid == _yuyuePressureMeasureUUid ||
                  chaUuid == _yuyuePressureResultUUid) {
                if (!element.isNotifying) {
                  try {
                    await element.setNotifyValue(true);
                  } catch (e) {
                    print(e);
                    // await element.setNotifyValue(true);
                  }
                }
                element.value.listen((event) {
                  // print("测量数据===>${event}");
                  var va16 = event.map((e) {
                    var data = e.toRadixString(16).toUpperCase();
                    if (data.length == 1) {
                      data = "0$data";
                    }
                    return data;
                  }).toList();
                  if (chaUuid == _yuyuePressureMeasureUUid) {
                    _yuyuePressureMeasureService = element;
                    if (va16.isEmpty) {
                      return;
                    }
                    var list = va16.sublist(1, 3);
                    var data = list.compare16ToStr();
                    if (_pressureMeasuringHandler != null) {
                      _pressureMeasuringHandler(
                          int.parse(data, radix: 16).toString());
                    }
                  } else if (chaUuid == _yuyuePressureResultUUid) {
                    _yuyuePressureResultService = element;
                    if (va16.isNotEmpty) {
                      _setYuwellPressureData(va16);
                    } else {
                      ///todo:未获取到测量数据
                      print("pressureResultData===>未测量到数据");
                    }
                  }
                });
              }
            });
          }
        });
      } else if (event == BluetoothDeviceState.disconnected) {
        linkDevices.remove(device);
        print("设备数量===》${linkDevices.length}");
      }
      if (_pressureStateHandler != null && _yuwellPressureState != event) {
        _yuwellPressureState = event;
        print("1231213123====>$event");
        _pressureStateHandler(event);
      }
    });
  }

  void _setYuwellPressureData(List<String> data) {
    var flags = int.parse(data[0], radix: 16).toRadixString(2).padLeft(8, "0");
    // print("resultFlages===>${flags}");

    var measureStatus = data.sublist(17);
    var statusValue = int.parse(measureStatus.compare16ToStr(), radix: 16)
        .toRadixString(2)
        .padLeft(16, "0")
        .reverseOrder();
    // print("measureStatus===>${statusValue.reverseOrder()}");

    var bodyMove = statusValue.substring(0, 1);
    var cuffFit = statusValue.substring(1, 2);
    var irregularPulse = statusValue.substring(2, 3);
    var pulseRange = statusValue.substring(3, 4);
    var postureCheck = statusValue.substring(4, 5);

    var highPressure =
        int.parse(data.sublist(1, 3).compare16ToStr(), radix: 16).toString();

    var lowPressure =
        int.parse(data.sublist(3, 5).compare16ToStr(), radix: 16).toString();

    var pulse =
        int.parse(data.sublist(14, 16).compare16ToStr(), radix: 16).toString();

    print("测量结果：收缩压：${highPressure}" "舒张压：${lowPressure}  脉率：${pulse}");

    // var map = {
    //   "measureStatus":statusValue,
    //   "lowPressure":lowPressure,
    //   "highPressure":highPressure,
    //   "pulse":pulse
    // };

    var model = YuwellPressureModel(
        measureStatus: statusValue,
        lowPressure: lowPressure,
        highPressure: highPressure,
        pulse: pulse,
        bodyMove: bodyMove,
        cuffFit: cuffFit,
        irregularPulse: irregularPulse,
        postureCheck: postureCheck,
        pulseRange: pulseRange);

    if (_pressureResultHandler != null) {
      _pressureResultHandler(model);
    }
  }

  ///鱼跃血糖仪
  BluetoothDevice _yuwellBloodDevice;
  BluetoothCharacteristic _yuwellBloodMeasureService;
  BluetoothDeviceState yuwellBloodMeasureState = BluetoothDeviceState.disconnected;

  ///鱼跃血糖仪设备uuid
  var _yuwellBloodServiceUUid = "00001808-0000-1000-8000-00805f9b34fb";

  ///血糖仪测量uuid
  var _yuwellBloodMeasureUUid = "00002a18-0000-1000-8000-00805f9b34fb";

  ///连接鱼跃血糖仪
  void connectYuyueBloodSugar(BluetoothDevice device) async {
    _yuwellBloodDevice = device;
    _yuwellBloodDevice.state.listen((event) async {
      if (event != BluetoothDeviceState.connected &&
          event != BluetoothDeviceState.connecting) {
        print("开始连接======>");
        _yuwellBloodDevice.connect();
      }
      print("yuyueBloodConnectStatus===>${event}");
      if (_yuwellBloodDevice != null) {
        linkDevices.remove(_yuwellBloodDevice);
      }

      linkDevices.add(_yuwellBloodDevice);
      var state = event;

      if (state == BluetoothDeviceState.connected) {
        var discoverServices = await device.discoverServices();

        discoverServices.forEach((element) {
          if (element.uuid.toString() == _yuwellBloodServiceUUid) {
            element.characteristics.forEach((element) async {
              var chaUuid = element.uuid.toString();
              if (chaUuid == _yuwellBloodMeasureUUid) {
                if (!element.isNotifying) {
                  try {
                    await element.setNotifyValue(true);
                  } catch (e) {
                    print(e);
                  }
                }
                element.value.listen((event) {
                  var va16 = event.map((e) {
                    var data = e.toRadixString(16).toUpperCase();
                    if (data.length == 1) {
                      data = "0$data";
                    }
                    return data;
                  }).toList();
                  print(
                      "pressureMeasureData1111===>${va16}\nuuid：${element.uuid.toString()}\n特征：${element.properties.toString()}");
                  if (chaUuid == _yuwellBloodMeasureUUid) {
                    _yuwellBloodMeasureService = element;
                    if (va16.isEmpty) {
                      return;
                    }
                    _setBloodSugarData(va16);
                    // print("pressureMeasureData===>${va16}");
                  }
                });
              }
            });
          }
        });
      } else if (state == BluetoothDeviceState.disconnected) {
        linkDevices.remove(device);
      }
      if (_bloodStateHandler != null) {
        yuwellBloodMeasureState = state;
        print("123123132====${state}");
        _bloodStateHandler(state);
      }
    });
  }

  void _setBloodSugarData(List<String> data) {
    var flags = int.parse(data[0], radix: 16)
        .toRadixString(2)
        .padLeft(8, "0")
        .reverseOrder();
    var unit = flags.substring(2, 3) == "1" ? "mol/L" : "";
    var valueData = data.sublist(10, 12).compare16ToStr();
    var first_v = int.parse(valueData.substring(0,1),radix: 16);
    var second_v = int.parse(valueData.substring(1),radix: 16);
    var bloodData = (second_v*1000)/(pow(10, 16-first_v));
    var model = BloodSugarModel(unit: unit,value: bloodData.toString());
    if(_bloodSugarHandler!=null){
      _bloodSugarHandler(model);
    }

  }

  ///血糖仪回调
  EventHandlerMap<BloodSugarModel> _bloodSugarHandler;
  // EventHandlerMap<String> _temErrorHandler;

  void addBloodSugarMeasureListener(
      {EventHandlerMap<BloodSugarModel> bloodSugarHandler}) {
    this._bloodSugarHandler = bloodSugarHandler;
  }

  void yuwellPressureDisconnect() {
    _yuyuePressureResultService?.setNotifyValue(false);
    _yuyuePressureMeasureService?.setNotifyValue(false);
    _yuyuePresureDevice?.disconnect();
    _yuyuePresureDevice = null;
    _yuyuePressureMeasureService = null;
    _yuyuePressureResultService = null;
    yuyuePressureDeviceState = BluetoothDeviceState.disconnected;
  }

  void yuwellBloodDisconnect(){
    _yuwellBloodMeasureService?.setNotifyValue(false);
    _yuwellBloodDevice?.disconnect();
    _yuwellBloodMeasureService = null;
    _yuwellBloodDevice = null;
    _yuwellPressureState = BluetoothDeviceState.disconnected;

  }

  void release() {
    temDeviceDisconnect();
    yuwellPressureDisconnect();
    yuwellBloodDisconnect();
    linkDevices.clear();
  }
}
