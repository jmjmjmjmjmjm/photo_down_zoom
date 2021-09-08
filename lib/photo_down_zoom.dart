library photo_down_zoom;

/// A Calculator.
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:photo_down_zoom/page_controller.dart';

//ignore: must_be_immutable
class PhotoDownZoom extends StatefulWidget {
  List imgs;
  PhotoDownZoom({Key? key, required this.imgs}) : super(key: key);
  @override
  _PhotoDownZoomState createState() => _PhotoDownZoomState(imgs: imgs);
}

class _PhotoDownZoomState extends State<PhotoDownZoom>
    with SingleTickerProviderStateMixin {
  List imgs;
  _PhotoDownZoomState({required this.imgs});

  int count = 1;
  PageController pageController = PageController();
  late AnimationController _animationController =
      AnimationController(vsync: this, duration: Duration(milliseconds: 400));

  countF(int c) {
    setState(() {
      count = c;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return showDial(context, PageController(initialPage: 0), imgs);
  }

  List transformationController = <TransformationController>[];
  List doubleTapDetails = <TapDownDetails>[];

  showDial(BuildContext context, PageController pageC, List imgs) {
    for (int i = 0; i < imgs.length + 1; i++) {
      transformationController.add(TransformationController());
      doubleTapDetails.add(TapDownDetails());
    }

    PageReController c = Get.put(PageReController());
    _handleDoubleTapDown(TapDownDetails details, int i) {
      doubleTapDetails[i] = details;
    }

    _handleDoubleTap(int i) {
      late Animation _animation;
      _animationController.addListener(() {
        transformationController[i].value = _animation.value;
      });

      if (transformationController[i].value != Matrix4.identity()) {
        _animation = Matrix4Tween(
          begin: transformationController[i].value,
          end: Matrix4.identity(),
        ).animate(
          CurveTween(curve: Curves.easeInOut).animate(_animationController),
        );
        _animationController.forward(from: 0);
        transformationController[i].value = Matrix4.identity();
        c.pageScroll.value = true;
        c.opacity.value = 1.0;
      } else {
        c.pageScroll.value = false;
        final position = doubleTapDetails[i].localPosition;
        var dy = -position.dy * 2;
        if (i == 1) dy = -645.0;
        if (dy < -900.0) return null;
        if (dy > -350) return null;
        if (dy > -580.0) dy = -580.0;
        if (dy < -700.0) dy = -700.0;

        transformationController[i].value = Matrix4.identity()
          ..translate(-position.dx * 2, dy)
          ..scale(3.0);

        _animation = Matrix4Tween(
          begin: Matrix4.identity(),
          end: transformationController[i].value,
        ).animate(
          CurveTween(curve: Curves.easeInOut).animate(_animationController),
        );
        c.opacity.value = 0.0;
        _animationController.forward(from: 0);
      }
    }

    return Container(
      color: Colors.grey.withOpacity(0.2),
      child: Stack(
        children: [
          Center(
            child: PageView.builder(
              physics: NeverScrollableScrollPhysics(),
              controller: pageC,
              onPageChanged: (value) {
                c.count.value = (value % imgs.length + 1);
              },
              itemBuilder: (context, index) => AbsorbPointer(
                absorbing: false,
                ignoringSemantics: false,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onDoubleTap: () => _handleDoubleTap(index % imgs.length),
                  onDoubleTapDown: (details) =>
                      _handleDoubleTapDown(details, index % imgs.length),
                  child: InteractiveViewer(
                    onInteractionEnd: (details) {
                      c.opacity.value = 0.0;
                      if (details.velocity.pixelsPerSecond.dx > 1500 ||
                          details.velocity.pixelsPerSecond.dx < -1500)
                        c.pageScroll.value = true;
                      else
                        c.pageScroll.value = false;
                      if (transformationController[index % imgs.length]
                              .value[0] ==
                          1.0) {
                        c.pageScroll.value = true;
                        c.opacity.value = 1.0;
                      }
                    },
                    transformationController:
                        transformationController[index % imgs.length],
                    child: Obx(
                      () => AbsorbPointer(
                        absorbing: c.pageScroll.value ? false : true,
                        child: Dismissible(
                          behavior: c.pageScroll.value
                              ? HitTestBehavior.deferToChild
                              : HitTestBehavior.translucent,
                          onDismissed: (direction) {
                            Navigator.pop(context);
                            c.count.value = 1;
                          },
                          direction: DismissDirection.down,
                          key: Key(''),
                          child: Container(
                            color: Colors.black,
                            child: Image.network(
                              imgs[index % imgs.length],
                              fit: BoxFit.fitHeight,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Obx(
            () => Opacity(
              opacity: c.opacity.value,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        c.count.value = 1;
                      },
                      child: Icon(
                        Icons.close,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
          Obx(
            () => Opacity(
              opacity: c.opacity.value,
              child: Padding(
                padding: const EdgeInsets.only(top: 13),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Obx(
                      () => Text(
                        c.count.value.toString() +
                            ' / ' +
                            imgs.length.toString(),
                        style: GoogleFonts.notoSans(
                            decoration: TextDecoration.none,
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 13),
                      ),
                    )
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
