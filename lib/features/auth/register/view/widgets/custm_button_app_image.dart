// import 'dart:io';

// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';

// class CustmBittonAppImage extends StatelessWidget {
//   const CustmBittonAppImage({
//     super.key,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return BlocConsumer<UdateProfailCubit, UpdateProfileState>(
//       listener: (context, state) {},
//       builder: (context, state) {
//         return GestureDetector(
//           onTap: () {
//          //   context.read<UdateProfailCubit>().showImageSource(context);
//           },
//           child: Center(
//             child: Stack(
//               alignment: AlignmentDirectional.bottomEnd,
//               children: [
//                 Container(
//                   height: 100.w,
//                   width: 100.w,
//                   decoration: BoxDecoration(
//                     color: Colors.grey[200],
//                     borderRadius: BorderRadius.circular(1000),
//                     border: Border.all(
//                       width: 1,
//                       color: Colors.black12,
//                     ),
//                   ),
//                   child: 
//                   // state.image.path == ""
//                   //     ? 
//                       ClipOval(
//                           child: CachedNetworkImage(
//                             fit: BoxFit.fill,
//                             placeholder: (context, url) => Padding(
//                               padding: const EdgeInsets.symmetric(
//                                   vertical: 34.0, horizontal: 10),
//                               child: Icon(
//                                 Icons.person,
//                                 size: 50.dg,
//                                 color: AppColors.mainBlack,
//                               ),
//                             ),
//                             imageUrl: SharedPreferenceHelper.getString(
//                                 PreferencesNames.imageUrl),
//                             errorWidget: (context, url, error) => Padding(
//                               padding: const EdgeInsets.all(24),
//                               child: SvgPicture.asset(Assets.navbarChatSelected,
//                                   fit: BoxFit.fill),
//                             ),
//                           ),
//                         )
//                       // :
//                       //  ClipOval(
//                       //     child: CircleAvatar(
//                       //     backgroundImage: FileImage(
//                       //       File(state.image.path),
//                       //     ),
//                       //   )),
//                 ),
//                 CircleAvatar(
//                   radius: 18.r,
//                   backgroundColor: AppColors.white,
//                   child: CircleAvatar(
//                     backgroundColor: AppColors.primary,
//                     radius: 16.r,
//                     child: Icon(
//                       size: 18.dg,
//                       Icons.edit,
//                       color: AppColors.white,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
// }
