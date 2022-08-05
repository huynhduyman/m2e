import 'dart:async';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:nfts/screens/user_screen/sign_in_user_info_screen.dart';
import 'package:nfts/screens/user_screen/sign_up_user_info_screen.dart';
import 'package:nfts/screens/user_screen/verify_user_info_screen.dart';
import 'package:nfts/screens/wallet_connect_thirdparty/wallet_connect_thirdparty.dart';
import 'package:provider/provider.dart';

import '../../../core/services/firebase_service.dart';
import '../../../core/utils/utils.dart';
import '../../../core/widgets/custom_placeholder/custom_placeholder.dart';
import '../../../core/widgets/custom_widgets.dart';
import '../../../provider/app_provider.dart';
import '../../../provider/auth_provider.dart';
import '../../../provider/fav_provider.dart';
import '../../../provider/user_provider.dart';
import '../../collection_screen/collection_screen.dart';
import '../../splash_screen/splash_screen.dart';
import '../../user_screen/edit_user_info_screen.dart';
import '../../nft_screen/nft_screen.dart';
import '../../user_screen/wallet_user_info_screen.dart';

class UserTab extends StatefulWidget {
  const UserTab({Key? key}) : super(key: key);

  @override
  State<UserTab> createState() => _UserTabState();
}

class _UserTabState extends State<UserTab>
    with
        SingleTickerProviderStateMixin,
        AutomaticKeepAliveClientMixin<UserTab> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
  GlobalKey<RefreshIndicatorState>();
  late TabController _tabController;

  // late final _userEmail;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  Future<User?> getUserByFirebase() async {
    // await _authProvider.getUser;
    final userFirebase = Provider.of<AuthProvider>(context, listen: false).getUser;
    String? userEmail = userFirebase?.email.toString();
    // debugPrint(userFirebase.toString());
    // _userFirebase = userFirebase;
    // setState(() => _userEmail = userEmail);
    return userFirebase;
  }

  _logOut() {
    // Provider.of<AppProvider>(context, listen: false).logOut(context);
    Provider.of<AuthProvider>(context, listen: false).signOut();
    scheduleMicrotask(() {
      Navigation.popAllAndPush(
        context,
        screen: const SplashScreen(),
      );
    });
  }

  _createNFT() {
    Navigation.push(
      context,
      name: 'create_nft',
    );
  }

  _createCollection() async {
    await Navigation.push(
      context,
      name: 'create_collection',
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(builder: (context, provider, child) {

      // if (FirebaseAuth.instance.currentUser != null) {
      //   debugPrint('User is signed in!');
      //   debugPrint(FirebaseAuth.instance.currentUser.toString());
      // }
      // debugPrint(authProvider.isSignedIn.toString());
      //
      // debugPrint(authProvider.getUser?.email.toString());

      // debugPrint(stateAuthProvider.isAnonymous.toString());
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
              // locator<WalletService>();
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
                          SizedBox(height: rh(60)),


                          Consumer<AuthProvider>(
                            builder: (context, authProvider, child) {


                              debugPrint(authProvider.state.toString());
                              if (authProvider.isSignedIn == false) {
                                return const LoadingIndicator();
                              }

                              return SingleChildScrollView(
                                padding: const EdgeInsets.symmetric(horizontal: space2x),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    //Image Leading
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(space1x),
                                      child: CachedNetworkImage(
                                        imageUrl: authProvider.getUser?.photoURL != null ? authProvider.getUser!.photoURL.toString() : 'https://image.shutterstock.com/image-vector/man-icon-flat-vector-260nw-1371568223.jpg',
                                        width: rf(56),
                                        height: rf(56),
                                        fit: BoxFit.cover,
                                        placeholder: (_, url) => CustomPlaceHolder(size: rw(56)),
                                        errorWidget: (context, url, error) =>
                                        const Icon(Icons.error),
                                      ),
                                    ),

                                    SizedBox(width: rw(space2x)),

                                    //Text
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: <Widget>[
                                          VerifiedText(
                                            text: authProvider.getUser?.displayName != null ? authProvider.getUser!.displayName.toString() : 'No name' ,
                                            isVerified: authProvider.getUser!.emailVerified,
                                          ),
                                          GestureDetector(
                                            onTap: () => Navigation.push(
                                              context,
                                              screen: const VerifyUserInfoScreen(),
                                            ),
                                            child: Row(
                                                children: <Widget>[
                                                  if (authProvider.getUser!.emailVerified == false)
                                                    Flexible(
                                                      child: Text(
                                                        'Unverified',
                                                        style: Theme.of(context).textTheme.caption,
                                                        overflow: TextOverflow.ellipsis,
                                                        maxLines: 1,
                                                        // softWrap: false,
                                                      ),
                                                    ),

                                                ]
                                            ),
                                          ),
                                          SizedBox(height: rh(4)),
                                          VerifiedText(
                                            text: authProvider.getUser!.email.toString(),
                                            isUpperCase: false,
                                            isVerified: authProvider.getUser!.emailVerified,
                                          ),
                                          SizedBox(height: rh(space1x)),
                                          Row(
                                            children: <Widget>[
                                              if (provider.user.metadata.isNotEmpty)
                                                Buttons.icon(
                                                  context: context,
                                                  svgPath: 'assets/images/twitter.svg',
                                                  right: rw(space2x),
                                                  semanticLabel: 'twitter',
                                                  onPressed: () {},
                                                  // onPressed: () => _openUrl(url),
                                                ),
                                              if (provider.user.metadata.isNotEmpty)
                                                Buttons.icon(
                                                  context: context,
                                                  icon: Iconsax.copy,
                                                  right: rw(space2x),
                                                  semanticLabel: 'Website',
                                                  onPressed: () {},
                                                ),

                                              Buttons.icon(
                                                  context: context,
                                                  icon: Iconsax.copy,
                                                  right: rw(space2x),
                                                  semanticLabel: 'Copy',
                                                  onPressed: () =>
                                                      copy(provider.user.uAddress.hex)),
                                              Buttons.icon(
                                                context: context,
                                                icon: Iconsax.share,
                                                right: rw(space2x),
                                                semanticLabel: 'Share',
                                                onPressed: () => share(
                                                  " Creator " + provider.user.uAddress.hex,
                                                  provider.user.image,
                                                  provider.user.uAddress.hex,
                                                ),
                                              ),
                                              Buttons.icon(
                                                context: context,
                                                icon: Iconsax.edit_2,
                                                right: rw(space2x),
                                                semanticLabel: 'Edit',
                                                onPressed: () => Navigation.push(
                                                  context,
                                                  screen: const EditUserInfoScreen(),
                                                ),
                                              ),
                                              Buttons.icon(
                                                context: context,
                                                icon: Icons.wallet,
                                                right: rw(space2x),
                                                semanticLabel: 'Wallet',
                                                onPressed: () => Navigation.push(
                                                  context,
                                                  screen: const WalletUserInfoScreen(),
                                                ),
                                              ),
                                              Buttons.icon(
                                                context: context,
                                                // icon: Icons.exit_to_app_rounded,
                                                icon: Iconsax.logout,
                                                right: rw(space2x),
                                                semanticLabel: 'Share',
                                                // onPressed: () {
                                                //   final status = Provider.of<AuthProvider>(context, listen: false).signOut();
                                                //   debugPrint('AuthProvider with signOut ${status.toString()}');
                                                //   // Navigation.popAllAndPush(context, screen: const SplashScreen());
                                                // },
                                                onPressed: _logOut,
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: rh(space1x)),

                                        ],
                                      ),
                                    ),
                                    SizedBox(width: rw(space1x)),
                                  ],
                                ),
                              );
                            },
                          ),

                          SizedBox(height: rh(space3x)),
                          //LINKS
                          // SingleChildScrollView(
                          //   padding: const EdgeInsets.symmetric(horizontal: space2x),
                          //   child: Row(
                          //     children: <Widget>[
                          //       if (provider.user.metadata.isNotEmpty)
                          //         Buttons.icon(
                          //           context: context,
                          //           svgPath: 'assets/images/twitter.svg',
                          //           right: rw(space2x),
                          //           semanticLabel: 'twitter',
                          //           onPressed: () {},
                          //           // onPressed: () => _openUrl(url),
                          //         ),
                          //       if (provider.user.metadata.isNotEmpty)
                          //         Buttons.icon(
                          //           context: context,
                          //           icon: Iconsax.copy,
                          //           right: rw(space2x),
                          //           semanticLabel: 'Website',
                          //           onPressed: () {},
                          //         ),
                          //
                          //       Buttons.icon(
                          //           context: context,
                          //           icon: Iconsax.copy,
                          //           right: rw(space2x),
                          //           semanticLabel: 'Copy',
                          //           onPressed: () =>
                          //               copy(provider.user.uAddress.hex)),
                          //       Buttons.icon(
                          //         context: context,
                          //         icon: Iconsax.share,
                          //         right: rw(space2x),
                          //         semanticLabel: 'Share',
                          //         onPressed: () => share(
                          //           " Creator " + provider.user.uAddress.hex,
                          //           provider.user.image,
                          //           provider.user.uAddress.hex,
                          //         ),
                          //       ),
                          //       Buttons.icon(
                          //         context: context,
                          //         icon: Iconsax.edit_2,
                          //         right: rw(space2x),
                          //         semanticLabel: 'Edit',
                          //         onPressed: () => Navigation.push(
                          //           context,
                          //           screen: const EditUserInfoScreen(),
                          //         ),
                          //       ),
                          //       // Buttons.icon(
                          //       //   context: context,
                          //       //   icon: Icons.login,
                          //       //   right: rw(space2x),
                          //       //   semanticLabel: 'Verify',
                          //       //   onPressed: () => Navigation.push(
                          //       //     context,
                          //       //     screen: const VerifyUserInfoScreen(),
                          //       //   ),
                          //       // ),
                          //       Buttons.icon(
                          //         context: context,
                          //         // icon: Icons.exit_to_app_rounded,
                          //         icon: Iconsax.logout,
                          //         right: rw(space2x),
                          //         semanticLabel: 'Share',
                          //         // onPressed: () {
                          //         //   final status = Provider.of<AuthProvider>(context, listen: false).signOut();
                          //         //   debugPrint('AuthProvider with signOut ${status.toString()}');
                          //         //   // Navigation.popAllAndPush(context, screen: const SplashScreen());
                          //         // },
                          //         onPressed: _logOut,
                          //       ),
                          //     ],
                          //   ),
                          // ),
                          //
                          // SizedBox(height: rh(space3x)),

                          //BUTTONS
                          SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: space2x),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: CustomOutlinedButton(
                                    text: 'Create Collection',
                                    onPressed: _createCollection,
                                  ),
                                ),
                                SizedBox(width: rw(space2x)),
                                Expanded(
                                  child: Buttons.flexible(
                                    context: context,
                                    text: 'Create NFT',
                                    onPressed: _createNFT,
                                  ),
                                ),
                              ],
                            ),
                          ),

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
                          text: 'Created'.toUpperCase(),
                          height: rh(30),
                        ),
                        Tab(
                          text: 'Collected'.toUpperCase(),
                          height: rh(30),
                        ),
                        Tab(
                          text: 'Favourite'.toUpperCase(),
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
                            subtitle: 'By ' + formatAddress(nft.creator),
                            isFav: favProvider.isFavNFT(nft),
                            onFavPressed: () => favProvider.setFavNFT(nft),
                          );
                        },
                      );
                    }),

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
                                  UpperCaseText(
                                    'Collections',
                                    style: Theme.of(context).textTheme.headline5,
                                  ),
                                  SizedBox(height: rh(space3x)),
                                  Consumer<FavProvider>(
                                      builder: (context, favProvider, child) {
                                        return ListView.separated(
                                          itemCount: provider.createdCollections.length,
                                          physics: const NeverScrollableScrollPhysics(),
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

                  // FAVOUTITE
                  if (provider.collectedNFTs.isEmpty)
                    const EmptyWidget(text: 'Nothing Collected yet')
                  else
                    Consumer<FavProvider>(builder: (context, favProvider, child) {
                      return CustomTabBar(
                        titles: const ['Collections', 'NFTS'],
                        tabs: [
                          if (favProvider.favCollections.isEmpty)
                            const EmptyWidget(
                              text: 'No Favorite collections',
                            )
                          else

                          //COLLECTION VIEW
                            ListView.separated(
                              itemCount: favProvider.favCollections.length,
                              padding: const EdgeInsets.only(
                                left: space2x,
                                right: space2x,
                                bottom: space3x,
                                top: space4x,
                              ),
                              separatorBuilder: (BuildContext context, int index) {
                                return SizedBox(height: rh(space2x));
                              },
                              itemBuilder: (BuildContext context, int index) {
                                final collection = favProvider.favCollections[index];
                                return GestureDetector(
                                  onTap: () => Navigation.push(
                                    context,
                                    screen: CollectionScreen(collection: collection),
                                  ),
                                  child: CollectionListTile(
                                    image: collection.image,
                                    title: collection.name,
                                    subtitle: 'By ${formatAddress(collection.creator)}',
                                    isFav: favProvider.isFavCollection(collection),
                                    onFavPressed: () =>
                                        favProvider.setFavCollection(collection),
                                  ),
                                );
                              },
                            ),
                          if (favProvider.favNFT.isEmpty)
                            const EmptyWidget(text: 'No Favorite NFTs')
                          else
                          //NFT VIEW
                            ListView.separated(
                              itemCount: favProvider.favNFT.length,
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
                                final nft = favProvider.favNFT[index];
                                return NFTCard(
                                  onTap: () => Navigation.push(
                                    context,
                                    screen: NFTScreen(nft: nft),
                                  ),
                                  heroTag: '${nft.cAddress}-${nft.tokenId}',
                                  image: nft.image,
                                  title: nft.name,
                                  subtitle: nft.cName,
                                  isFav: favProvider.isFavNFT(nft),
                                  onFavPressed: () => favProvider.setFavNFT(nft),
                                );
                              },
                            ),
                        ],
                      );
                    }),
                ],
              ),
            )
        )
      );
    });
  }

  @override
  bool get wantKeepAlive => true;
}
