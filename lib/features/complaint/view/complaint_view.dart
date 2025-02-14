import 'package:flutter/material.dart';
import 'package:taxista/features/complaint/view/widgets/complaint_view_body.dart';

List generalComplaintList = [];

// getGeneralCcomplaint(type) async {
//   dynamic result;
//   try {
//     print('Drops URl Comp');
//     var response = await http.get(
//       Uri.parse('${url}api/v1/common/complaint-titles?complaint_type=$type'),
//       headers: {'Authorization': 'Bearer ${bearerToken[0].token}'},
//     );
//     if (response.statusCode == 200) {
//       generalComplaintList = jsonDecode(response.body)['data'];
//       print('Drops URl Comp 200 ${generalComplaintList}');
//       result = 'success';
//     } else if (response.statusCode == 401) {
//       print('Drops URl Comp 401 ${response.body}');
//       print('Drops URl Comp 401 ${response.request}');
//       print('Drops URl Comp 401 ${response.reasonPhrase}');
//       result = 'logout';
//     } else {
//       print('Drops URl Comp 500');

//       debugPrint(response.body);
//       result = 'failed';
//     }
//   } catch (e) {
//     print('Drops URl Comp $e');

//     if (e is SocketException) {
//       internet = false;
//       result = 'no internet';
//     }
//   }
//   return result;
// }

// makeGeneralComplaint(complaintDesc) async {
//   dynamic result;
//   try {
//     var response =
//         await http.post(Uri.parse('${url}api/v1/common/make-complaint'),
//             headers: {
//               'Authorization': 'Bearer ${bearerToken[0].token}',
//               'Content-Type': 'application/json'
//             },
//             body: jsonEncode({
//               'complaint_title_id': generalComplaintList[complaintType]['id'],
//               'description': complaintDesc,
//             }));
//     if (response.statusCode == 200) {
//       result = 'success';
//     } else if (response.statusCode == 401) {
//       result = 'logout';
//     } else {
//       debugPrint(response.body);
//       result = 'failed';
//     }
//   } catch (e) {
//     if (e is SocketException) {
//       internet = false;
//       result = 'no internet';
//     }
//   }
//   return result;
// }

// makeRequestComplaint() async {
//   dynamic result;
//   try {
//     var response =
//         await http.post(Uri.parse('${url}api/v1/common/make-complaint'),
//             headers: {
//               'Authorization': 'Bearer ${bearerToken[0].token}',
//               'Content-Type': 'application/json'
//             },
//             body: jsonEncode({
//               'complaint_title_id': generalComplaintList[complaintType]['id'],
//               'description': complaintDesc,
//               'request_id': myHistory[selectedHistory]['id']
//             }));
//     if (response.statusCode == 200) {
//       result = 'success';
//     } else if (response.statusCode == 401) {
//       result = 'logout';
//     } else {
//       debugPrint(response.body);
//       result = 'failed';
//     }
//   } catch (e) {
//     if (e is SocketException) {
//       internet = false;
//       result = 'no internet';
//     }
//   }
//   return result;
// }

class ComplaintView extends StatelessWidget {
  const ComplaintView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: ComplaintViewBody(),
    );
  }
}
