import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../models/wishlist_item.dart';
import '../services/wishlist_service.dart';
import '../../widgets/custom_bottom_nav.dart';
import 'child_home_screen.dart';
import 'child_task_view_screen.dart';

class WishlistScreen extends StatefulWidget {
  final String parentId;
  final String childId;

  const WishlistScreen({
    Key? key,
    required this.parentId,
    required this.childId,
  }) : super(key: key);

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  int _navBarIndex = 2; // Wishlist tab index

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF1F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFF643FDB),
        foregroundColor: Colors.white,
        elevation: 0,
         automaticallyImplyLeading: false, // Disable back button
        title: Text(
          'My Wishlist',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            fontFamily: 'SF Pro Text',
          ),
        ),
        actions: [],
      ),
      body: Column(
        children: [
          // Total Value Card
          _buildTotalValueCard(),
          
          // Add Item Button
          _buildAddItemButton(),
          
          // Wishlist Items
          Expanded(
            child: _buildWishlistItems(),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _navBarIndex,
        onTap: (index) => _onNavTap(context, index),
      ),
    );
  }

  Widget _buildTotalValueCard() {
    return Container(
      margin: EdgeInsets.all(20.w),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF643FDB), Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20.r,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.favorite,
              color: Colors.white,
              size: 24.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Total Wishlist Value",
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.9),
                    fontFamily: 'SF Pro Text',
                  ),
                ),
                StreamBuilder<List<WishlistItem>>(
                  stream: WishlistService.getWishlistItems(widget.parentId, widget.childId),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      double total = 0.0;
                      for (var item in snapshot.data!) {
                        total += item.price;
                      }
                      return Text(
                        "${total.toStringAsFixed(2)} SAR",
                        style: TextStyle(
                          fontSize: 28.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'SF Pro Text',
                        ),
                      );
                    }
                    return Text(
                      "0.00 SAR",
                      style: TextStyle(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'SF Pro Text',
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddItemButton() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: ElevatedButton.icon(
        onPressed: () => _showAddItemDialog(),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF643FDB),
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 24.w),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          elevation: 2,
        ),
        icon: Icon(
          Icons.add,
          size: 20.sp,
        ),
        label: Text(
          'Add item to wishlist',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            fontFamily: 'SF Pro Text',
          ),
        ),
      ),
    );
  }

  Widget _buildWishlistItems() {
    return StreamBuilder<List<WishlistItem>>(
      stream: WishlistService.getWishlistItems(widget.parentId, widget.childId),
      builder: (context, snapshot) {
        print('🔍 WishlistScreen: Stream state: ${snapshot.connectionState}');
        print('🔍 WishlistScreen: Has data: ${snapshot.hasData}');
        print('🔍 WishlistScreen: Has error: ${snapshot.hasError}');
        if (snapshot.hasError) {
          print('🔍 WishlistScreen: Error details: ${snapshot.error}');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF643FDB)),
            ),
          );
        }

        if (snapshot.hasError) {
          print('❌ WishlistScreen: Error loading wishlist: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64.sp,
                  color: const Color(0xFFA29EB6),
                ),
                SizedBox(height: 16.h),
                Text(
                  'Error loading wishlist',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1C1243),
                    fontFamily: 'SF Pro Text',
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  '${snapshot.error}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: const Color(0xFF718096),
                    fontFamily: 'SF Pro Text',
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16.h),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      // Trigger rebuild to retry
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF643FDB),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    'Retry',
                    style: TextStyle(fontFamily: 'SF Pro Text'),
                  ),
                ),
                SizedBox(height: 16.h),
                ElevatedButton(
                  onPressed: () => _showAddItemDialog(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF47C272),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    'Add First Item',
                    style: TextStyle(fontFamily: 'SF Pro Text'),
                  ),
                ),
              ],
            ),
          );
        }

        final items = snapshot.data ?? [];

        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.favorite_border,
                  size: 64.sp,
                  color: const Color(0xFFA29EB6),
                ),
                SizedBox(height: 16.h),
                Text(
                  'No items in your wishlist',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1C1243),
                    fontFamily: 'SF Pro Text',
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Tap the + button to add your first item',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: const Color(0xFF718096),
                    fontFamily: 'SF Pro Text',
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return _buildWishlistItemCard(item);
          },
        );
      },
    );
  }

  Widget _buildWishlistItemCard(WishlistItem item) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Row(
        children: [
          // Item details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'SF Pro Text',
                    color: const Color(0xFF1C1243),
                  ),
                ),
                if (item.description.isNotEmpty) ...[
                  SizedBox(height: 4.h),
                  Text(
                    item.description,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: const Color(0xFF718096),
                      fontFamily: 'SF Pro Text',
                    ),
                  ),
                ],
                SizedBox(height: 8.h),
                Text(
                  "${item.price.toStringAsFixed(2)} SAR",
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF47C272),
                    fontFamily: 'SF Pro Text',
                  ),
                ),
              ],
            ),
          ),
          
          // Action buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => _showEditItemDialog(item),
                icon: Icon(
                  Icons.edit,
                  color: const Color(0xFF643FDB),
                  size: 20.sp,
                ),
              ),
              IconButton(
                onPressed: () => _showDeleteItemDialog(item),
                icon: Icon(
                  Icons.delete,
                  color: const Color(0xFFFF6A5D),
                  size: 20.sp,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddItemDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Text(
          "Add to Wishlist",
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            fontFamily: 'SF Pro Text',
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: "Item Name",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Price (SAR)",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: "Description (Optional)",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: TextStyle(
                color: const Color(0xFFA29EB6),
                fontFamily: 'SF Pro Text',
                fontSize: 14.sp,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty && priceController.text.isNotEmpty) {
                try {
                  final price = double.parse(priceController.text);
                  await WishlistService.addWishlistItem(
                    widget.parentId,
                    widget.childId,
                    nameController.text,
                    price,
                    descriptionController.text,
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Item added to wishlist!'),
                      backgroundColor: const Color(0xFF47C272),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to add item: $e'),
                      backgroundColor: const Color(0xFFFF6A5D),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF643FDB),
              foregroundColor: Colors.white,
            ),
            child: Text(
              "Add",
              style: TextStyle(fontFamily: 'SF Pro Text', fontSize: 14.sp),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditItemDialog(WishlistItem item) {
    final nameController = TextEditingController(text: item.name);
    final priceController = TextEditingController(text: item.price.toString());
    final descriptionController = TextEditingController(text: item.description);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Text(
          "Edit Item",
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            fontFamily: 'SF Pro Text',
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: "Item Name",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Price (SAR)",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: "Description (Optional)",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: TextStyle(
                color: const Color(0xFFA29EB6),
                fontFamily: 'SF Pro Text',
                fontSize: 14.sp,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty && priceController.text.isNotEmpty) {
                try {
                  final price = double.parse(priceController.text);
                  await WishlistService.updateWishlistItem(
                    widget.parentId,
                    widget.childId,
                    item.id,
                    nameController.text,
                    price,
                    descriptionController.text,
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Item updated successfully!'),
                      backgroundColor: const Color(0xFF47C272),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to update item: $e'),
                      backgroundColor: const Color(0xFFFF6A5D),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF643FDB),
              foregroundColor: Colors.white,
            ),
            child: Text(
              "Update",
              style: TextStyle(fontFamily: 'SF Pro Text', fontSize: 14.sp),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteItemDialog(WishlistItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Text(
          "Delete Item",
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            fontFamily: 'SF Pro Text',
          ),
        ),
        content: Text(
          "Are you sure you want to delete '${item.name}' from your wishlist?",
          style: TextStyle(
            fontSize: 14.sp,
            fontFamily: 'SF Pro Text',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: TextStyle(
                color: const Color(0xFFA29EB6),
                fontFamily: 'SF Pro Text',
                fontSize: 14.sp,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await WishlistService.deleteWishlistItem(
                  widget.parentId,
                  widget.childId,
                  item.id,
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Item deleted successfully!'),
                    backgroundColor: const Color(0xFF47C272),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to delete item: $e'),
                    backgroundColor: const Color(0xFFFF6A5D),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6A5D),
              foregroundColor: Colors.white,
            ),
            child: Text(
              "Delete",
              style: TextStyle(fontFamily: 'SF Pro Text', fontSize: 14.sp),
            ),
          ),
        ],
      ),
    );
  }

  void _onNavTap(BuildContext context, int index) {
    if (index == _navBarIndex) return;

    setState(() {
      _navBarIndex = index;
    });

    switch (index) {
      case 0:
        // Navigate to Home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomeScreen(
              parentId: widget.parentId,
              childId: widget.childId,
            ),
          ),
        );
        break;
      case 1:
        // Navigate to Tasks
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ChildTaskViewScreen(
              parentId: widget.parentId,
              childId: widget.childId,
            ),
          ),
        );
        break;
      case 2:
        // Already on Wishlist
        break;
      case 3:
        // Navigate to Leaderboard
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Leaderboard coming soon')),
        );
        break;
    }
  }
}
