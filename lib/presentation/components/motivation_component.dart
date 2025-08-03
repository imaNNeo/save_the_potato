import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/extensions.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';
import 'package:save_the_potato/presentation/game_colors.dart';
import 'package:save_the_potato/presentation/helpers/audio_helper.dart';
import 'package:save_the_potato/presentation/potato_game.dart';
import 'package:save_the_potato/service_locator.dart';

class MotivationComponent extends PositionComponent
    with HasPaint, HasGameReference<PotatoGame> {
  final MotivationWordType motivationWordType;
  final Color color;
  late final AudioHelper _audioHelper;
  late final TextComponent _textComponent;
  final double inDuration;
  final double outDuration;

  double get totalDuration => inDuration + outDuration;

  MotivationComponent({
    super.position,
    this.color = GameColors.greenColor,
    required this.motivationWordType,
    required this.inDuration,
    required this.outDuration,
  });

  List<Vector2> randomParticlePoints(Vector2 textOffset) {
    // /// We can either use our cached points (they're perfectly distributed)
    final randomPoints = _bestCachedRandomPoints
        .random(game.rnd)
        .map((e) => Vector2(e[0].toDouble(), e[1].toDouble()))
        .toList();

    /// Or we can use the below logic to generate them randomly,
    /// so there might be some overlaps:
    // final textApproximateRect = Rect.fromCenter(
    //   center: textOffset.toOffset(),
    //   width: 340,
    //   height: 68,
    // );
    // final expandedRect = textApproximateRect.expandBy(80, 60);
    // const particlesCount = 10;
    // final randomPoints = List.generate(
    //   particlesCount,
    //   (i) => expandedRect.randomPointExcludeRect(
    //     textApproximateRect,
    //   ),
    // );

    return randomPoints;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _audioHelper = getIt.get<AudioHelper>();
    _audioHelper.playMotivationWord(motivationWordType);
    final textOffset = Vector2(0, -150);
    const particlesCount = 12;
    final particlesLifespan = totalDuration * 0.9;
    final List<Sprite> sprites = [
      await Sprite.load('sparkle/sparkle1.png'),
      await Sprite.load('sparkle/sparkle2.png'),
    ];
    final randomSprites = List.generate(
      particlesCount,
      (i) => sprites.random(),
    );

    final randomPoints = randomParticlePoints(textOffset);
    add(ParticleSystemComponent(
      particle: Particle.generate(
        count: particlesCount,
        lifespan: particlesLifespan,
        generator: (i) {
          return AcceleratedParticle(
            position: randomPoints[i],
            child: ComputedParticle(
              renderer: (canvas, particle) {
                final sprite = randomSprites[i];
                final scaleProgress = TweenSequence(
                  <TweenSequenceItem<double>>[
                    TweenSequenceItem(
                      tween: Tween(begin: 0.0, end: 0.8),
                      weight: 1,
                    ),
                    TweenSequenceItem(
                      tween: Tween(begin: 0.8, end: 1.0),
                      weight: 3,
                    ),
                    TweenSequenceItem(
                      tween: Tween(begin: 1.0, end: 0.0),
                      weight: 1,
                    ),
                  ],
                ).transform(
                  Curves.fastOutSlowIn.transform(
                    particle.progress,
                  ),
                );
                final size =
                    Tween(begin: 0.0, end: 18.0).transform(scaleProgress);

                final opacityTween = TweenSequence(
                  <TweenSequenceItem<double>>[
                    TweenSequenceItem(
                      tween: Tween(begin: 0.0, end: 1.0),
                      weight: 1,
                    ),
                    TweenSequenceItem(
                      tween: Tween(begin: 1.0, end: 0.0),
                      weight: 1,
                    ),
                  ],
                );
                canvas.rotate(particle.progress * pi * 2);
                sprite.render(
                  canvas,
                  size: Vector2.all(size),
                  anchor: Anchor.center,
                  overridePaint: Paint()
                    ..colorFilter = ColorFilter.mode(
                      color.withOpacity(
                        opacityTween.transform(particle.progress),
                      ),
                      BlendMode.srcIn,
                    ),
                );
              },
            ),
          );
        },
      ),
    ));

    add(_textComponent = TextComponent(
      priority: 2,
      text: motivationWordType.text,
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 28,
          fontFamily: 'Cookies',
        ),
      ),
      children: [
        ScaleEffect.by(
          Vector2.all(2.5),
          EffectController(
            duration: inDuration,
            curve: Curves.fastOutSlowIn,
          ),
        ),
        MoveByEffect(
          textOffset,
          EffectController(
            duration: inDuration,
            curve: Curves.fastOutSlowIn,
          ),
        ),
        OpacityEffect.to(
          0.7,
          target: this as OpacityProvider,
          EffectController(
            duration: inDuration,
            curve: Curves.fastOutSlowIn,
          ),
        ),
        OpacityEffect.fadeOut(
          target: this as OpacityProvider,
          EffectController(
            duration: outDuration,
            curve: Curves.easeOutSine,
            startDelay: inDuration,
          ),
        )
      ],
    ));
    setOpacity(0);
    add(RemoveEffect(
      delay: max(totalDuration, particlesLifespan),
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);
    _textComponent.textRenderer =
        (_textComponent.textRenderer as TextPaint).copyWith(
      (style) => style.copyWith(
        color: const Color(0xFF00FF15).withOpacity(opacity),
      ),
    );
  }
}

enum MotivationWordType {
  amazing('Amazing!', 'amazing.wav'),
  goodJob('Good Job!', 'good_job.wav'),
  ohGreat('Oh Great!', 'oh_great.wav'),
  ohNice('Oh Nice!', 'oh_nice.wav'),
  perfect('Perfect!', 'perfect.wav');

  final String text;
  final String assetName;

  const MotivationWordType(this.text, this.assetName);
}

/// These are some random generated numbers for particles around the motivation
/// words. They are perfectly distributed around the text. So we cached them
/// to use in the runtime instead of having a random function to generate them.
/// This way, we prevent generating overlapping particles.
const _bestCachedRandomPoints = [
  [
    [120.4372430244158, -206.55805268281787],
    [174.10432468245688, -153.27661230350435],
    [31.97593483568258, -213.13642099077217],
    [-81.06611824938753, -186.27998962673303],
    [-168.97546497926498, -93.01136218050777],
    [-151.5941546344903, -184.7456976558257],
    [109.07919939143454, -100.92714055912363],
    [-165.92120631350312, -115.1445164490175],
    [174.69711434461112, -164.82644610933437],
    [-69.81371116426408, -86.42134766449172],
    [-106.94452306693196, -100.9749143125868],
    [178.4371828940727, -109.49882574971055]
  ],
  [
    [-181.42313942178012, -152.70088549385326],
    [160.98623367583542, -100.5617642628527],
    [14.864579223227082, -93.66564637446993],
    [-133.5825066163353, -88.51199135407417],
    [194.97353849582572, -181.55566088318585],
    [5.454701532162744, -101.88674105939576],
    [98.04273881443328, -207.27115016357988],
    [124.66498223960326, -201.38343926306254],
    [-181.60335073074398, -98.91698926569669],
    [-112.05405106053084, -186.9164665602473],
    [171.62065348318595, -143.341030612412],
    [36.29511206635971, -197.33817596261434]
  ],
  [
    [155.11824429927776, -102.16224012885202],
    [93.66364782093797, -208.41548550355472],
    [-34.05043784068238, -209.35971165939458],
    [88.62857189626669, -185.4342436364165],
    [173.14251608968527, -130.22977586768724],
    [-63.1480953886809, -99.06137055186696],
    [52.902387081823974, -105.52264674704215],
    [-120.55998972765454, -110.83420314215456],
    [100.15710543354868, -192.45305516862066],
    [-187.08516096576034, -140.4558732354707],
    [-166.09925935846388, -210.34392182462886],
    [136.60536523661744, -192.76618187887746]
  ],
  [
    [-134.06062175158453, -104.54142771399202],
    [177.94305998520667, -196.58799631181853],
    [78.00781212906247, -201.60253985917308],
    [163.06963502541646, -103.9317290160875],
    [52.0816668513973, -185.4268159559732],
    [95.32207456680266, -103.27037586457419],
    [31.24274856802623, -90.07706780297369],
    [-43.46406937028294, -185.16537780790298],
    [-133.85758029981025, -190.92041551042632],
    [-198.30258671465913, -147.7230978225237],
    [103.10249858044398, -99.15876186454447],
    [178.50472657777397, -151.3153979043238]
  ],
  [
    [-79.79641439498408, -205.4198027375128],
    [50.267793563748455, -198.18652359481896],
    [79.52888775271794, -209.32872621377675],
    [-37.436616302947954, -207.60189518534997],
    [96.89348099715994, -187.7468188788996],
    [-205.13323500064553, -143.06849796766178],
    [-14.985902760253396, -101.79641316437953],
    [201.15075691827303, -125.00213887877145],
    [176.95495304982427, -90.19385199396592],
    [209.70519743732382, -166.3716445379548],
    [-50.72205812298992, -202.28922589922036],
    [-65.02466612424408, -111.91315644334301]
  ],
  [
    [77.24695743045788, -106.46204826461079],
    [-60.62008763919491, -194.17627016256725],
    [145.18240821546766, -114.98973133088239],
    [186.35537288001166, -101.02725951839284],
    [-109.0751617194402, -190.6531132492446],
    [202.1334603732085, -142.9289687080269],
    [171.88295868588995, -141.47016473206656],
    [33.608755708497625, -88.05726808529711],
    [-168.23357254964347, -189.82019557116956],
    [-187.78772321870855, -160.3476381836348],
    [39.692974438976876, -211.20061665174893],
    [-199.83025440001035, -122.67902572035175]
  ],
  [
    [207.05689810095544, -168.40049682988],
    [-185.53615585740317, -205.42147272478095],
    [-127.45533250265882, -113.46354274491466],
    [31.9951590026609, -86.29801748784786],
    [-17.72300430466396, -99.35074938933528],
    [-69.19199853219843, -90.76107434004315],
    [-41.79857143585883, -106.42560215821801],
    [-6.844107918107568, -196.71874675813766],
    [-163.12726540934977, -89.47938347674496],
    [110.74961665559664, -89.82982705095884],
    [184.27425126789677, -90.00722083786906],
    [86.41993551848174, -186.89352015576827]
  ],
  [
    [16.921078421771938, -200.31841446236984],
    [-191.36564858596938, -88.17139827760224],
    [146.64132271028558, -103.90271685988868],
    [-2.185864369104877, -87.1157961078797],
    [-204.92162584133047, -105.17756102107985],
    [83.82797735244486, -206.53606853029146],
    [158.46014097216812, -101.31163548551642],
    [-68.76315831479127, -91.02282412672191],
    [-92.77405299553108, -94.23346832524156],
    [-57.342610004212275, -199.41235180605582],
    [-107.95790457719924, -195.2198380001557],
    [179.28970960358896, -212.85323861177523]
  ],
  [
    [201.1814767586436, -204.70624985523415],
    [20.06160183625596, -113.86302117419758],
    [-159.4113251471627, -184.50707214434686],
    [-197.62898849400707, -89.27558959847941],
    [-115.45932660528477, -191.66693568586265],
    [56.39934434643118, -185.91839310823204],
    [60.28508850677673, -211.7591932880169],
    [-190.96439504099988, -175.9257414755589],
    [-93.67168930630274, -115.16850866948991],
    [184.31685532773213, -109.6379487310275],
    [-195.32211046527544, -106.99338310757916],
    [101.77906717388925, -200.55795201297758]
  ],
  [
    [112.30592156676852, -93.33430088110846],
    [183.97527762201304, -169.65173891772872],
    [-201.9709522110085, -114.46815505499974],
    [-104.87821778612077, -190.35334565051733],
    [-48.070757384936286, -201.7304027189059],
    [137.3617012503533, -203.86068712807895],
    [68.21255963279634, -91.83755935504861],
    [27.429944469216935, -195.1047664279559],
    [-195.74415185433233, -133.16858128804282],
    [187.06084120958735, -111.45834552130759],
    [41.47711459899162, -193.3147411442162],
    [-145.1291181823658, -189.51598718284126]
  ],
  [
    [-19.240476777649803, -108.11423553937203],
    [-97.48247211271924, -106.90084067835137],
    [46.67908302206621, -90.5737630136878],
    [-202.45457124066436, -158.09649245411742],
    [-162.8484076431923, -99.95240643420844],
    [163.48117211889848, -189.99344534148912],
    [202.32050889850035, -124.23886892639766],
    [-140.5035480839979, -115.6288425295829],
    [183.92253250451188, -129.39119207973613],
    [170.77032105508886, -93.46944171125446],
    [40.489510355391246, -185.61497317699445],
    [-124.61778605172643, -204.1964401552802]
  ],
  [
    [178.13120398609294, -103.24481652855329],
    [92.54612513288669, -197.4952698373491],
    [-106.64136809190234, -193.22602800951609],
    [-93.95839758669965, -196.64626675208154],
    [-175.50279898240535, -192.2949265859261],
    [123.26794789249811, -111.04741095913862],
    [-6.005197433147487, -114.2903141138041],
    [156.90013367287946, -197.37437614675704],
    [-153.23462840294962, -109.96803738727655],
    [192.1207744052777, -197.83463026496582],
    [-196.45658631178196, -161.440453432649],
    [17.666076282183212, -115.6164483298789]
  ],
];
