import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:oneisolatebeta/audio_controller.dart';

Uri uriImage = Uri.parse(
    "https://p1.pxfuel.com/preview/798/707/803/transistor-radio-radio-retro-silver.jpg");

List<MediaItem> meditationQueue = [
  MediaItem(
    id: "https://stream.zeno.fm/pzhdue9unv8uv",
    title: "Meditation 1",
    artUri: uriImage,
  ),
  MediaItem(
    id: "https://stream.zeno.fm/s19xvtgy8p8uv",
    title: "Meditation 2",
    artUri: uriImage,
  ),
  MediaItem(
    id: "https://stream.zeno.fm/qn8sz4rrad0uv",
    title: "Meditation 3",
    artUri: uriImage,
  ),
];

List<MediaItem> hindinQueue = [
  MediaItem(
    id: "https://stream.zeno.fm/8e9q38tg7zquv",
    title: "Hindi 1",
    artUri: uriImage,
  ),
  MediaItem(
    id: "https://stream.zeno.fm/71k1qkhtsg0uv",
    title: "Hindi 2",
    artUri: uriImage,
  ),
  MediaItem(
    id: "https://stream.zeno.fm/x87qpwpr2p8uv",
    title: "Hindi 3",
    artUri: uriImage,
  ),
];

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final AudioController audioController = Get.find<AudioController>();
  BannerAd? _bannerAd;

  @override
  void initState() {
    super.initState();
    _bannerAd = BannerAd(
      size: AdSize.banner,
      adUnitId: BannerAd.testAdUnitId,
      listener: BannerAdListener(onAdFailedToLoad: (ad, error) {
        //Utilities.shout("List Error is ${error.message}");
      }),
      request: AdRequest(),
    );

    _bannerAd!.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() => SafeArea(
            child: Column(
              children: [
                QueueContainer(queue: meditationQueue, queueName: "Meditation"),
                QueueContainer(queue: hindinQueue, queueName: "Hindi"),
                Visibility(
                  visible: audioController.queueLoaded.value,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _button(Icons.skip_previous, audioController.previous),
                      if (audioController.isPlaying.value)
                        _button(Icons.pause, audioController.pause)
                      else
                        _button(Icons.play_arrow, audioController.resume),
                      _button(Icons.skip_next, audioController.next),
                    ],
                  ),
                  
                ),
                Spacer(),

                Container(
            //margin: EdgeInsets.only(top: 8),
            child: AdWidget(ad: _bannerAd!),
            alignment: Alignment.center,
            //width: bannerAd.size.width.toDouble(),
            height: _bannerAd!.size.height.toDouble(),
          ),
              ],
            ),
          )),
    );
  }

  IconButton _button(IconData iconData, VoidCallback onPressed) => IconButton(
        icon: Icon(iconData),
        iconSize: 64.0,
        onPressed: onPressed,
      );
}

class QueueContainer extends StatelessWidget {
  final List<MediaItem> queue;
  final String queueName;
  final AudioController audioController = Get.find<AudioController>();
  QueueContainer({Key? key, required this.queue, required this.queueName})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(queueName),
        Row(
          children: queue
              .map((MediaItem mediaItem) => GestureDetector(
                    onTap: () {
                      audioController.playRadioStation(mediaItem, queue);
                    },
                    child: MediaItemContainer(
                      mediaItem: mediaItem,
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class MediaItemContainer extends StatelessWidget {
  final MediaItem mediaItem;
  const MediaItemContainer({Key? key, required this.mediaItem})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        height: 100,
        child: AspectRatio(
          aspectRatio: 1,
          child: Container(
            child: Center(
              child: Text(mediaItem.title),
            ),
          ),
        ),
      ),
    );
  }
}
