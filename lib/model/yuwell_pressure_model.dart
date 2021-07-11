class YuwellPressureModel {
  ///测量状态
  String measureStatus;

  ///舒张压
  String lowPressure;

  ///收缩压
  String highPressure;

  ///脉率
  String pulse;

  ///误动状态 (0:No 1:Yes)
  String bodyMove;

  ///袖带佩戴检测 (0:No 1:Yes)
  String cuffFit;

  ///心率不齐检测 (0:No 1:Yes)
  String irregularPulse;

  ///脉搏范围检测 (0: Within the range 1:Exceeds upper limit
  /// 2: Less than lower limit 3:Reserved)
  String pulseRange;

  ///体位检测 (0: 恰当 1:不恰当)
  String postureCheck;

  YuwellPressureModel(
      {this.measureStatus,
      this.lowPressure,
      this.highPressure,
      this.pulse,
      this.bodyMove,
      this.cuffFit,
      this.irregularPulse,
      this.postureCheck,
      this.pulseRange});

  YuwellPressureModel.fromJson(Map data) {
    measureStatus = data["measureStatus"];
    lowPressure = data["lowPressure"];
    highPressure = data["highPressure"];
    pulse = data["pulse"];
    bodyMove = data["bodyMove"];
    cuffFit = data["cuffFit"];
    irregularPulse = data["irregularPulse"];
    postureCheck = data["postureCheck"];
    pulseRange = data["pulseRange"];
  }
}
