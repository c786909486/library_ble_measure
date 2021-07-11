class BaseMeasureModel{
  String statusCode;
  String msg;

  BaseMeasureModel({this.statusCode, this.msg});

  BaseMeasureModel.fromJson(Map<String,dynamic> json){
    statusCode = json["statusCode"];
    msg = json["msg"];
  }
}