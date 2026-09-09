part of '../map_page.dart';

extension _MapPermissionStates on _MapsState {
  Widget buildLocationDisabledState(Size media) {
    return Expanded(
      child: Container(
        width: media.width * 1,
        alignment: Alignment.center,
        child: Container(
          padding: EdgeInsets.all(media.width * 0.05),
          width: media.width * 0.6,
          height: media.width * 0.3,
          decoration: BoxDecoration(
              color: page, borderRadius: BorderRadius.circular(10)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                languages[choosenLanguage]['text_enable_location'],
                style: GoogleFonts.notoSans(
                    fontSize: media.width * sixteen,
                    color: textColor,
                    fontWeight: FontWeight.bold),
              ),
              Container(
                alignment: Alignment.centerRight,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      state = '';
                    });
                    getLocs();
                  },
                  child: Text(
                    languages[choosenLanguage]['text_ok'],
                    style: GoogleFonts.notoSans(
                        fontWeight: FontWeight.bold,
                        fontSize: media.width * twenty,
                        color: buttonColor),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget buildLocationPermissionState(Size media) {
    return Expanded(
      child: Container(
        width: media.width * 1,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: ClipPath(
                    clipper: ShapePainter(),
                    child: Image.asset(
                      "assets/images/2005.jpg",
                      width: media.width,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(
                  height: 20.h,
                ),
                MyText(
                  text: languages[choosenLanguage]['text_allowpermission1'],
                  size: media.width * eighteen,
                  textAlign: TextAlign.center,
                  fontweight: FontWeight.bold,
                  color: Colors.blue,
                ),
                SizedBox(
                  height: 12.h,
                ),
                MyText(
                  text: languages[choosenLanguage]['text_allowpermission2'],
                  size: 16.sp,
                  textAlign: TextAlign.center,
                  color: Colors.black,
                  fontweight: FontWeight.w600,
                ),
                SizedBox(
                  height: 20.h,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: media.width * 0.07,
                      width: media.width * 0.07,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.green[200],
                      ),
                      child: const Icon(Icons.location_on_outlined,
                          color: Colors.white),
                    ),
                    SizedBox(width: media.width * 0.02),
                    MyText(
                      text: languages[choosenLanguage]
                          ['text_loc_permission_user'],
                      size: 16.sp,
                      fontweight: FontWeight.w500,
                      color: Colors.grey,
                    )
                  ],
                ),
                Container(
                    padding: EdgeInsets.all(media.width * 0.05),
                    child: Button(
                        onTap: () async {
                          getLocationPermission();
                        },
                        text: languages[choosenLanguage]['text_next'])),
              ],
            )),
          ],
        ),
      ),
    );
  }
}
