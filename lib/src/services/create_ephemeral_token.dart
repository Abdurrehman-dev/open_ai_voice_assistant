import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;


class CreateEphemeralToken {
  Future<Map<String,dynamic>?> createEmpheralToken(String apiKey,{String? model,String? instructions,String? voice,double? speed,List<Map<String,dynamic>>? tools}) async {
    try {
      final body = <String,dynamic>{"model": model??'gpt-4o-realtime-preview'};
      if(instructions!=null){
        body['instructions'] = instructions;
      }
      if(voice != null){
        body['voice'] = voice;
      }
      if(speed!=null){
        body['speed'] = speed;
      }
      if(tools!=null){
        body['tools'] = tools;
      }
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/realtime/sessions'),
        headers: {
          "Authorization": 'Bearer $apiKey',
          "Content-Type": "application/json",
        },
        body: jsonEncode(body),
      );
      if(response.statusCode == 200){
        return jsonDecode(response.body);
      }else{
        throw ErrorDescription(jsonDecode(response.body));
      }
    } catch (e) {
      throw ErrorDescription(e.toString());
    }
  }
}
