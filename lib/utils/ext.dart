extension CompareNumber on List<String> {
  String compare16ToStr() {
    // this.sort((o1,o2){
    //   return int.parse(o1,radix: 16).compareTo(int.parse(o2,radix: 16));
    // });
    var list = this.reversed;
    var str = "";
    for(var item in list){
      str+=item;
    }
    return str;
  }
}

extension ReverseOrder on String{
  String reverseOrder(){
    String text = "";
    for(var i = this.length-1;i>=0;i--){
      var s = this.substring(i,i+1);

      text+=s;
    }

    return text;
  }
}



