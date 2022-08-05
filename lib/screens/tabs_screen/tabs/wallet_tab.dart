import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';


import '../../../core/utils/utils.dart';
import '../../../core/widgets/custom_widgets.dart';
import '../../../provider/fav_provider.dart';
import '../../collection_screen/collection_screen.dart';
import '../../nft_screen/nft_screen.dart';
import '../../../provider/user_provider.dart';

import '../../../core/services/wallet_service.dart';
import '../../../locator.dart';
import '../../../provider/wallet_provider.dart';

class WalletTab extends StatefulWidget {
  const WalletTab({Key? key}) : super(key: key);

  @override
  State<WalletTab> createState() => _WalletTabState();
}

class _WalletTabState extends State<WalletTab>
    with
        SingleTickerProviderStateMixin,
        AutomaticKeepAliveClientMixin<WalletTab> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
  GlobalKey<RefreshIndicatorState>();
  final _walletService = locator<WalletService>();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<UserProvider>(builder: (context, provider, child) {
      if (provider.state == UserState.loading) {
        return const LoadingIndicator();
      }

      final user = provider.user;

      return Scaffold(
          body: RefreshIndicator(
              key: _refreshIndicatorKey,
              color: Colors.white,
              backgroundColor: Colors.blue,
              strokeWidth: 1.0,
              notificationPredicate: (notification) {
                // with NestedScrollView local(depth == 2) OverscrollNotification are not sent
                if (notification is OverscrollNotification || Platform.isIOS) {
                  return notification.depth == 2;
                }
                return notification.depth == 0;
              },
              onRefresh: () async {
                // Replace this delay with the code to be executed during refresh
                locator<WalletService>();
                // and return a Future when code finishs execution.
                return Future<void>.delayed(const Duration(seconds: 3));
              },
              child: NestedScrollView(
                headerSliverBuilder: (BuildContext context, bool isBoxScrolled) {
                  return <Widget>[
                    SliverAppBar(
                      elevation: 0,
                      pinned: true,
                      floating: true,
                      snap: true,
                      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                      expandedHeight: rh(284),
                      toolbarHeight: 0,
                      collapsedHeight: 0,
                      flexibleSpace: FlexibleSpaceBar(
                        collapseMode: CollapseMode.pin,
                        background: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            SizedBox(height: rh(20)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: space2x),
                              child: Column(
                                  children: [
                                    // const CustomAppBar(),
                                    SizedBox(height: rh(space3x)),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: const <Widget>[
                                        Icon(
                                          Icons.wallet,
                                          color: Colors.blue,
                                          size: 32.0,
                                          semanticLabel: 'Text to announce in accessibility modes',
                                        ),
                                      ],
                                    ),
                                    UpperCaseText(
                                      'Wallet',
                                    ),
                                    // SizedBox(height: rh(space1x)),

                                    Consumer<WalletProvider>(
                                      builder: (context, provider, child) {
                                        return Column(
                                          children: [
                                            SizedBox(height: rh(1)),
                                            DataTile(
                                              label: 'Balance',
                                              value: ' ${formatBalance(provider.balance)} MATIC',
                                            ),
                                            SizedBox(height: rh(space1x)),
                                            DataTile(
                                              label: 'Public Address',
                                              value: provider.address.hex,
                                              icon: Iconsax.copy,
                                              onIconPressed: () => copy(provider.address.hex),
                                            ),
                                            SizedBox(height: rh(space1x)),
                                            DataTile(
                                              label: 'Private Key',
                                              value: '************',
                                              icon: Iconsax.copy,
                                              onIconPressed: () => copy(_walletService.getPrivateKey()),
                                            ),
                                            // SizedBox(height: rh(space2x)),
                                            // Buttons.text(
                                            //   // width: double.infinity,
                                            //   context: context,
                                            //   text: 'Get Test Matic',
                                            //   onPressed: () => openUrl(
                                            //     'https://faucet.polygon.technology',
                                            //     context,
                                            //   ),
                                            // ),
                                            SizedBox(height: rh(space2x)),
                                          ],
                                        );
                                      },
                                    ),
                                ]
                              )
                            ),
                            //BUTTONS
                            SizedBox(height: rh(space2x)),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: space2x),
                              child: Divider(),
                            ),
                            SizedBox(height: rh(space1x)),
                          ],
                        ),
                      ),
                      bottom: TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        indicatorWeight: 1.4,
                        indicatorColor: Colors.black,
                        labelStyle: Theme.of(context).textTheme.headline3,
                        labelPadding: const EdgeInsets.symmetric(horizontal: space2x),
                        unselectedLabelStyle: Theme.of(context).textTheme.headline5,
                        tabs: [
                          Tab(
                            text: 'Tokens'.toUpperCase(),
                            height: rh(30),
                          ),
                          Tab(
                            text: 'Nfts'.toUpperCase(),
                            height: rh(30),
                          ),
                        ],
                      ),
                    ),
                  ];
                },
                body: TabBarView(
                  controller: _tabController,
                  children: [
                    //CREATED UI
                    if (provider.createdCollections.isEmpty && provider.singles.isEmpty)
                      const EmptyWidget(text: 'Nothing Created yet')
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: space2x),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              SizedBox(height: rh(space3x)),
                              //COLLECTIONS
                              if (provider.createdCollections.isNotEmpty)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    // UpperCaseText(
                                    //   'Collections',
                                    //   style: Theme.of(context).textTheme.headline5,
                                    // ),
                                    SizedBox(height: rh(space3x)),
                                    Consumer<FavProvider>(
                                        builder: (context, favProvider, child) {
                                          return ListView.separated(
                                            itemCount: provider.createdCollections.length,
                                            // physics: const NeverScrollableScrollPhysics(),
                                            shrinkWrap: true,
                                            padding: EdgeInsets.zero,
                                            separatorBuilder:
                                                (BuildContext context, int index) {
                                              return SizedBox(height: rh(space2x));
                                            },
                                            itemBuilder: (BuildContext context, int index) {
                                              final collection =
                                              provider.createdCollections[index];

                                              return GestureDetector(
                                                onTap: () => Navigation.push(context,
                                                    screen: CollectionScreen(
                                                      collection: collection,
                                                    )),
                                                child: CollectionListTile(
                                                  image: collection.image,
                                                  title: collection.name,
                                                  subtitle: '${collection.nItems} items',
                                                  isSubtitleVerified: false,
                                                  isFav: favProvider
                                                      .isFavCollection(collection),
                                                  onFavPressed: () => favProvider
                                                      .setFavCollection(collection),
                                                ),
                                              );
                                            },
                                          );
                                        }),

                                    //DIVIDER
                                    SizedBox(height: rh(space3x)),
                                    const Divider(),
                                    SizedBox(height: rh(space3x)),
                                  ],
                                ),

                              //SINGLES

                              if (provider.singles.isNotEmpty)
                                UpperCaseText(
                                  'Singles',
                                  style: Theme.of(context).textTheme.headline5,
                                ),
                              if (provider.singles.isNotEmpty)
                                SizedBox(height: rh(space3x)),

                              if (provider.singles.isNotEmpty)
                                Consumer<FavProvider>(
                                    builder: (context, favProvider, child) {
                                      return ListView.separated(
                                        itemCount: 3,
                                        physics: const NeverScrollableScrollPhysics(),
                                        shrinkWrap: true,
                                        padding: const EdgeInsets.only(
                                          bottom: space3x,
                                        ),
                                        separatorBuilder:
                                            (BuildContext context, int index) {
                                          return SizedBox(height: rh(space3x));
                                        },
                                        itemBuilder: (BuildContext context, int index) {
                                          final nft = provider.singles[index];
                                          return NFTCard(
                                            key: PageStorageKey(nft.cAddress),
                                            onTap: () => Navigation.push(context,
                                                screen: NFTScreen(nft: nft)),
                                            image: nft.image,
                                            title: nft.name,
                                            subtitle: nft.cName,
                                            isFav: favProvider.isFavNFT(nft),
                                            onFavPressed: () => favProvider.setFavNFT(nft),
                                          );
                                        },
                                      );
                                    }),
                            ],
                          ),
                        ),
                      ),

                    //COLLECTED UI
                    if (provider.collectedNFTs.isEmpty)
                      const EmptyWidget(text: 'Nothing Collected yet')
                    else
                      Consumer<FavProvider>(builder: (context, favProvider, child) {
                        return ListView.separated(
                          itemCount: provider.collectedNFTs.length,
                          padding: const EdgeInsets.only(
                            left: space2x,
                            right: space2x,
                            bottom: space3x,
                            top: space3x,
                          ),
                          separatorBuilder: (BuildContext context, int index) {
                            return SizedBox(height: rh(space3x));
                          },
                          itemBuilder: (BuildContext context, int index) {
                            final nft = provider.collectedNFTs[index];
                            return NFTCard(
                              key: PageStorageKey(nft.tokenId),
                              onTap: () =>
                                  Navigation.push(context, screen: NFTScreen(nft: nft)),
                              heroTag: '${nft.cAddress}-${nft.tokenId}',
                              image: nft.image,
                              title: nft.name,
                              subtitle: 'By ${formatAddress(nft.creator)}',
                              isFav: favProvider.isFavNFT(nft),
                              onFavPressed: () => favProvider.setFavNFT(nft),
                            );
                          },
                        );
                      }),
                  ],
                ),
              )
          )
      );
    });
    //
    // return Scaffold(
    //     body: RefreshIndicator(
    //       key: _refreshIndicatorKey,
    //       color: Colors.white,
    //       backgroundColor: Colors.blue,
    //       strokeWidth: 1.0,
    //       notificationPredicate: (notification) {
    //         // with NestedScrollView local(depth == 2) OverscrollNotification are not sent
    //         if (notification is OverscrollNotification || Platform.isIOS) {
    //           return notification.depth == 2;
    //         }
    //         return notification.depth == 0;
    //       },
    //       onRefresh: () async {
    //         // Replace this delay with the code to be executed during refresh
    //         locator<WalletService>();
    //         // and return a Future when code finishs execution.
    //         return Future<void>.delayed(const Duration(seconds: 3));
    //       },
    //
    //
    //
    //
    //       child: Padding(
    //         // physics: const AlwaysScrollableScrollPhysics(),
    //         padding: const EdgeInsets.symmetric(horizontal: space2x),
    //         child: Column(
    //           crossAxisAlignment: CrossAxisAlignment.center,
    //           children: [
    //             const CustomAppBar(),
    //             // SizedBox(height: rh(space1x)),
    //             Row(
    //               mainAxisAlignment: MainAxisAlignment.spaceAround,
    //               children: const <Widget>[
    //                 Icon(
    //                   Icons.wallet,
    //                   color: Colors.blue,
    //                   size: 32.0,
    //                   semanticLabel: 'Text to announce in accessibility modes',
    //                 ),
    //               ],
    //             ),
    //             UpperCaseText(
    //               'nfts Wallet',
    //             ),
    //             // SizedBox(height: rh(space1x)),
    //
    //             Consumer<WalletProvider>(
    //               builder: (context, provider, child) {
    //                 return Column(
    //                   children: [
    //                     SizedBox(height: rh(1)),
    //                     DataTile(
    //                       label: 'Balance',
    //                       value: ' ' + formatBalance(provider.balance) + ' MATIC',
    //                     ),
    //                     SizedBox(height: rh(space1x)),
    //                     DataTile(
    //                       label: 'Public Address',
    //                       value: provider.address.hex,
    //                       icon: Iconsax.copy,
    //                       onIconPressed: () => copy(provider.address.hex),
    //                     ),
    //                     SizedBox(height: rh(space1x)),
    //                     DataTile(
    //                       label: 'Private Key',
    //                       value: '************',
    //                       icon: Iconsax.copy,
    //                       onIconPressed: () => copy(_walletService.getPrivateKey()),
    //                     ),
    //                     // SizedBox(height: rh(space2x)),
    //                     // Buttons.text(
    //                     //   // width: double.infinity,
    //                     //   context: context,
    //                     //   text: 'Get Test Matic',
    //                     //   onPressed: () => openUrl(
    //                     //     'https://faucet.polygon.technology',
    //                     //     context,
    //                     //   ),
    //                     // ),
    //                     SizedBox(height: rh(space2x)),
    //                   ],
    //                 );
    //               },
    //             ),
    //             Expanded(
    //               child: Consumer<FavProvider>(builder: (context, favProvider, child) {
    //                 return CustomTabBar(
    //                   titles: const ['TOKENS', 'NFTS'],
    //                   tabs: [
    //                     if (favProvider.favCollections.isEmpty)
    //                       const EmptyWidget(
    //                         text: 'No Favorite collections',
    //                       )
    //                     else
    //
    //                     //COLLECTION VIEW
    //                       ListView.separated(
    //                         physics: const AlwaysScrollableScrollPhysics(),
    //                         itemCount: favProvider.favCollections.length,
    //                         padding: const EdgeInsets.only(
    //                           left: space2x,
    //                           right: space2x,
    //                           bottom: space3x,
    //                           top: space4x,
    //                         ),
    //                         separatorBuilder: (BuildContext context, int index) {
    //                           return SizedBox(height: rh(space2x));
    //                         },
    //                         itemBuilder: (BuildContext context, int index) {
    //                           final collection = favProvider.favCollections[index];
    //                           return GestureDetector(
    //                             onTap: () => Navigation.push(
    //                               context,
    //                               screen: CollectionScreen(collection: collection),
    //                             ),
    //                             child: CollectionListTile(
    //                               image: collection.image,
    //                               title: collection.name,
    //                               subtitle: 'By ${formatAddress(collection.creator)}',
    //                               isFav: favProvider.isFavCollection(collection),
    //                               onFavPressed: () =>
    //                                   favProvider.setFavCollection(collection),
    //                             ),
    //                           );
    //                         },
    //                       ),
    //                     if (favProvider.favNFT.isEmpty)
    //                       const EmptyWidget(text: 'No Favorite NFTs')
    //                     else
    //                     //NFT VIEW
    //                       ListView.separated(
    //                         physics: const AlwaysScrollableScrollPhysics(),
    //                         itemCount: favProvider.favNFT.length,
    //                         padding: const EdgeInsets.only(
    //                           left: space2x,
    //                           right: space2x,
    //                           bottom: space3x,
    //                           top: space3x,
    //                         ),
    //                         separatorBuilder: (BuildContext context, int index) {
    //                           return SizedBox(height: rh(space3x));
    //                         },
    //                         itemBuilder: (BuildContext context, int index) {
    //                           final nft = favProvider.favNFT[index];
    //                           return NFTCard(
    //                             onTap: () => Navigation.push(
    //                               context,
    //                               screen: NFTScreen(nft: nft),
    //                             ),
    //                             heroTag: '${nft.cAddress}-${nft.tokenId}',
    //                             image: nft.image,
    //                             title: nft.name,
    //                             subtitle: nft.cName,
    //                             isFav: favProvider.isFavNFT(nft),
    //                             onFavPressed: () => favProvider.setFavNFT(nft),
    //                           );
    //                         },
    //                       ),
    //                   ],
    //                 );
    //               }),
    //             ),
    //           ],
    //         ),
    //       ),
    //     )
    // );
  }
  @override
  bool get wantKeepAlive => true;
}

class CollectionView extends StatelessWidget {
  const CollectionView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
