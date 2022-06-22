class Success {
  Success({
    required this.result,
  });

  Result result;

  factory Success.fromJson(Map<String, dynamic> json) => Success(
        result: Result.fromJson(json["result"]),
      );

  Map<String, dynamic> toJson() => {
        "result": result.toJson(),
      };
}

class Result {
  Result({
    required this.status,
    required this.message,
    required this.code,
  });

  int status;
  String message;
  String code;

  factory Result.fromJson(Map<String, dynamic> json) => Result(
        status: json["status"],
        message: json["message"],
        code: json["code"],
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
        "code": code,
      };
}
