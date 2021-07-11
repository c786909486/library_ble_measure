import 'package:library_ble_measure/model/base_messure_model.dart';

class TemModel{
  String temValue;
  String measureType;

  TemModel({this.temValue,this.measureType});


  TemModel.fromJson(Map data){
    temValue = data["temValue"];
    measureType = data["measureType"];
  }


  @override
  String toString() {

    return "temValue:${temValue},measureType:${measureType}";
  }

}