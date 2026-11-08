part of '../drop_loc_select.dart';

mixin _DropLocationView on State<DropLocation>, _DropLocationController {
  Widget buildDropLocation(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return PopScope(
      canPop: popFunction(),
      onPopInvoked: (did) {
        if (_getDropDetails) {
          setState(() {
            _getDropDetails = false;
          });
        }
      },
      child: Material(
        child: ValueListenableBuilder(
            valueListenable: valueNotifierHome.value,
            builder: (context, value, child) {
              return Directionality(
                textDirection: (languageDirection == 'rtl') ? TextDirection.rtl : TextDirection.ltr,
                child: Container(
                  height: media.height * 1,
                  width: media.width * 1,
                  color: page,
                  child: Stack(
                    children: [
                      _dropMapLayer(media),
                      if (_state == '3' && !_getDropDetails)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Align(
                              alignment: const Alignment(0, -.12),
                              child: _TaxistaCenterPin(
                                moving: _isMapMoving,
                                selectingPickup: widget.selectingPickup || widget.from == 0,
                              ),
                            ),
                          ),
                        ),
                      _dropAddressSheet(media),
                      _dropSavedAddressSheet(media),
                      _dropSaveAddress(media),
                      _dropLocationPermission(media),
                      (_isLoading == true) ? const Positioned(child: Loading()) : Container(),
                      (internet == false)
                          ? Positioned(
                              top: 0,
                              child: NoInternet(
                                onTap: () {
                                  setState(() {
                                    internetTrue();
                                  });
                                },
                              ))
                          : Container(),
                    ],
                  ),
                ),
              );
            }),
      ),
    );
  }
}
