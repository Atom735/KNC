class MyClient {
  static MyClient _instance;
  MyClient._init();
  factory MyClient() => _instance ?? (_instance = MyClient._init());
}
