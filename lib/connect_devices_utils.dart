import 'package:flutter_blue/flutter_blue.dart';
import 'package:library_ble_measure/model/ble_device_state_model.dart';

import 'ble_measure_plugin.dart';

typedef void OnDeviceStateListener(BleDeviceStateModel event);

class ConnectDeviceUtils {
  static FlutterBlue _flutterBlue = FlutterBlue.instance;
  static List<BluetoothDevice> devicesList = [];

  ///家测宝设备名称
  static String _temDeviceName = "IR Thermo";

  ///鱼跃血压仪名称
  static String _yuwellPressureName = "Yuwell BP";

  ///鱼跃血糖仪名称
  static String _yuwellBloodSugarName = "Yuwell Glucose";

  static void initMeasureDevice() {
    _flutterBlue.startScan();
    _flutterBlue.scanResults.listen((results) {
      for (ScanResult r in results) {
        if (r.device.name.isNotEmpty) {
          if (!devicesList.contains(r.device)) {
            devicesList.add(r.device);
          }
          if (r.device.name.contains(_temDeviceName) &&
              BluetoothDeviceState.connected !=
                  BleMeasurePlugin.instance.temDeviceState) {
            BleMeasurePlugin.instance.connectTemDevice(r.device);
          }

          if (r.device.name.contains(_yuwellPressureName) &&
              BluetoothDeviceState.connected !=
                  BleMeasurePlugin.instance.yuyuePressureDeviceState) {
            BleMeasurePlugin.instance.connectYuyuePresure(r.device);
          }

          if (r.device.name.contains(_yuwellBloodSugarName) &&
              BluetoothDeviceState.connected !=
                  BleMeasurePlugin.instance.yuyuePressureDeviceState) {
            BleMeasurePlugin.instance.connectYuyueBloodSugar(r.device);
          }
        }
      }
    });
    _initBleStateListener();
  }
 static  var stateModel = BleDeviceStateModel(
    temLink: false, pressureLink: false, bloodLink: false, );

  static void _initBleStateListener() {

    BleMeasurePlugin.instance.addDeviceStateListener(
        pressureStateHandler: (state) async {
          if (state == BluetoothDeviceState.connected) {
            stateModel.pressureLink = true;
          } else {
            stateModel.pressureLink = false;
          }
          // _deviceStateListener(stateModel);
          print("pressureStateHandler===>${state}");
          listeners.forEach((element) {
            element(stateModel);
          });
        },
        temStateHandler: (state) async {
          if (state == BluetoothDeviceState.connected) {
            stateModel.temLink = true;
          } else {
            stateModel.temLink = false;
          }
          print("temStateHandler===>${state}");
          listeners.forEach((element) {
            element(stateModel);
          });
        },
        bloodStateHandler: (state) async {
          if (state == BluetoothDeviceState.connected) {
            stateModel.bloodLink = true;
          } else {
            stateModel.bloodLink = false;
          }
          print("bloodStateHandler===>${state}");
          listeners.forEach((element) {
            element(stateModel);
          });
        }
    );
  }

  // static OnDeviceStateListener _deviceStateListener;
  static List<OnDeviceStateListener> listeners = [];

  static void addOnDeviceStateListener(OnDeviceStateListener listener) {
    listeners.add(listener);
  }

  static void removeListener(OnDeviceStateListener listener){
    listeners.remove(listener);
  }

  static void release() {
    BleMeasurePlugin.instance.release();
    listeners.clear();
    _flutterBlue.stopScan();
    // _flutterBlue = null;
  }
}
