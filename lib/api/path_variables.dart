import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiKeys {
  static final String encryptionKey = dotenv.env["ENCRYPTION_KEY"]!;
  static final String pathVariable = dotenv.env['PATH_VARIABLE']!;
  static final String dbConn = dotenv.env['DB_CONN']!;

  static final String cronJob = dotenv.env["JOB_API"]!;
  static final String saveChkList = dotenv.env["SAVE_CHECKLIST"]!;
  static final String chkTmplList = dotenv.env["CHK_TEMPLATE"]!;
  static final String login = dotenv.env["LOGIN_PHP"]!;
  static final String uploadApi = dotenv.env["UPLOAD_API"]!;
  static final String uploadSignatureImg = dotenv.env["UPLOAD_SIGNATURE_IMG"]!;
  static final String delSignatureImg = dotenv.env["DELETE_SIGNATURE"]!;
  static final String getImg = dotenv.env["GET_IMG"]!;
  static final String getImgJson = dotenv.env["GET_IMG_JSON"]!;
  static final String downloadFile = dotenv.env["DOWNLOAD_FILE"]!;
  static final String approveReports = dotenv.env["APPROVE_REPORTS"]!;
  static final String brgyReports = dotenv.env["BRGY_REPORTS"]!;
  static final String reportDetails = dotenv.env["REPORT_DETAILS"]!;
  static final String assignEstablishment = dotenv.env["ASSIGN_ESTABLISHMENT"]!;
  static final String reportsList = dotenv.env["REPORTS_LIST"]!;
}
