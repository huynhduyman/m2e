import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:health/health.dart';

import '../../../core/utils/utils.dart';
import '../../../provider/health_provider.dart';

class WorkoutsTab extends StatefulWidget {
  const WorkoutsTab({Key? key}) : super(key: key);

  @override
  State<WorkoutsTab> createState() => _WorkoutsTabState();
}

class _WorkoutsTabState extends State<WorkoutsTab> with
    SingleTickerProviderStateMixin,
    AutomaticKeepAliveClientMixin<WorkoutsTab> {

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
  GlobalKey<RefreshIndicatorState>();

  late TabController _tabController;
  var healthPoint = <HealthDataPoint>[];
  var error = "";
  var isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    // fetchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Fetch data points from the health plugin and show them in the app.
  Future fetchData() async {
    try {
      isLoading = true;
      final healthData = await Provider.of<HealthProvider>(context, listen: false).fetchData();
      healthPoint.addAll(healthData);
      error = "";
      isLoading = false;
    } catch (e) {
      error = e.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<HealthProvider>(builder: (context, provider, child) {
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
                fetchData();
                // and return a Future when code finishs execution.
                return Future<void>.delayed(const Duration(seconds: 3));
              },
              child: NestedScrollView(
                headerSliverBuilder: (BuildContext context, bool isBoxScrolled) {
                  return <Widget>[
                    Consumer<HealthProvider>(builder: (context, provider, child) {
                      // if (provider.state == HealthState.loading) {
                      //   return const LoadingIndicator();
                      // }
                      // final healthData = provider.fetchData();
                      provider.fetchStepsData();
                      final steps = provider.steps.toString();
                      debugPrint(steps.toString());
                      // update the UI to display the results

                      // debugPrint(healthData.toString());
                      return SliverAppBar(
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
                                      SizedBox(height: rh(space4x)),
                                      Card(
                                        child: InkWell(
                                          splashColor: Colors.blue.withAlpha(30),
                                          onTap: () {
                                            debugPrint('Card tapped.');
                                          },
                                          child: SizedBox(
                                            width: 300,
                                            height: 100,
                                            child: Text('Total number of steps: $steps'),
                                          ),
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Column(
                                            children: [
                                              IconButton(
                                                onPressed: () {
                                                  fetchData();
                                                },
                                                icon: const Icon(Icons.nordic_walking),
                                              ),
                                              Text('$steps Steps',
                                                  style: const TextStyle(color: Colors.orange)
                                              ),
                                            ],
                                          ),
                                          SizedBox(width: rw(space2x)),
                                          Column(
                                            children: [
                                              IconButton(
                                                onPressed: () {
                                                  fetchData();
                                                },
                                                icon: const Icon(Icons.nordic_walking),
                                              ),
                                              const Text('My Learning',
                                                  style: TextStyle(color: Colors.orange)
                                              ),
                                            ],
                                          ),
                                          SizedBox(width: rw(space2x)),
                                          Column(
                                            children: [
                                              IconButton(
                                                onPressed: () {
                                                  fetchData();
                                                },
                                                icon: const Icon(Icons.nordic_walking),
                                              ),
                                              const Text('My Learning',
                                                  style: TextStyle(color: Colors.orange)
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
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
                              text: 'My Activity'.toUpperCase(),
                              height: rh(30),
                            ),
                            // Tab(
                            //   text: 'Nfts'.toUpperCase(),
                            //   height: rh(30),
                            // ),
                          ],
                        ),
                      );

                    }),



                  ];
                },
                body:const Center(
                  child: Text('Content',
                      style: TextStyle(color: Colors.orange)
                  ),
                ),
              )
          )
      );
    });
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
