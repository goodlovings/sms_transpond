import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telephony/telephony.dart';
import 'package:background_sms/background_sms.dart';
import 'package:fluttertoast/fluttertoast.dart';

// 后台监听短信
onBackgroundMessage(SmsMessage message) async {
  final prefs = await SharedPreferences.getInstance();
  final sc = prefs.getString('smscode') ?? "";
  if (sc.isNotEmpty) {
    BackgroundSms.sendMessage(
        phoneNumber: sc, message: "${message.body} (from:${message.address})");
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // 转发的短信信息
  String _message = "";
  // 转发到手机号
  String _smcode = "";
  // 是否开始监听
  bool isListen = false;

  TextEditingController textFieldController = TextEditingController();

  // 插件
  final telephony = Telephony.instance;

  @override
  void initState() {
    super.initState();
    initStartData();
  }

  initStartData() async {
    final prefs = await SharedPreferences.getInstance();
    final sc = prefs.getString('smscode') ?? "";
    // 保存过号码
    if (sc.isNotEmpty) {
      textFieldController.text = sc;
      setState(() {
        _smcode = sc;
      });
    }
  }

  // 监听收到短信并发送
  onMessage(SmsMessage message) async {
    setState(() {
      _message = "${message.body}(from:${message.address})";
    });
    BackgroundSms.sendMessage(phoneNumber: _smcode, message: _message);
  }

  // 设置转发号码
  setSmsCode() async {
    setState(() {
      _smcode = textFieldController.text;
    });
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('smscode', textFieldController.text);
  }

  // 开始监听
  listenChnage() async {
    if (_smcode.isNotEmpty) {
      // 开启
      if (!isListen) {
        final bool? result = await telephony.requestPhoneAndSmsPermissions;
        if (result != null && result) {
          telephony.listenIncomingSms(
              onNewMessage: onMessage,
              onBackgroundMessage: onBackgroundMessage);
          setState(() {
            isListen = !isListen;
          });
        } else {
          Fluttertoast.showToast(
              msg: "请先同意授权",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.CENTER,
              timeInSecForIosWeb: 1,
              backgroundColor: Colors.black,
              textColor: Colors.white,
              fontSize: 16.0);
        }
      } else {
        // 关闭
        telephony.listenIncomingSms(
            onNewMessage: (SmsMessage message) => {},
            listenInBackground: false);
        setState(() {
          isListen = !isListen;
        });
      }
    } else {
      Fluttertoast.showToast(
          msg: "请先填写手机号码",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.black,
          textColor: Colors.white,
          fontSize: 16.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
      appBar: AppBar(
        title: const Text('短信转移'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: TextField(
              controller: textFieldController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: '转移到的手机号',
              ),
              keyboardType: TextInputType.phone,
              onChanged: (value) => {setSmsCode()},
            ),
          ),
          ElevatedButton(
            onPressed: () {
              listenChnage();
            },
            style: ButtonStyle(
              backgroundColor: MaterialStatePropertyAll(
                  isListen ? Colors.green[500] : Colors.black),
              fixedSize: const MaterialStatePropertyAll(Size(375, 50)),
              foregroundColor: const MaterialStatePropertyAll(Colors.white),
            ),
            child: Text(isListen ? '监听中···' : '开始监听'),
          )
        ],
      ),
    ));
  }
}
