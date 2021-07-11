class BleDeviceStateModel{
  bool temLink = false;
  bool pressureLink = false;
  bool bloodLink = false;
  bool get allLink => temLink&&pressureLink&&bloodLink;
  bool get hasLink => temLink||pressureLink||bloodLink;

  BleDeviceStateModel({this.temLink, this.pressureLink, this.bloodLink});
}