import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'styles.dart';
import 'assets.dart';

/// الصفحة الرئيسية للمحفظة الرقمية.
class TrydosWalletHomePage extends StatefulWidget {
  const TrydosWalletHomePage({super.key});

  @override
  State<TrydosWalletHomePage> createState() => _TrydosWalletHomePageState();
}

class _TrydosWalletHomePageState extends State<TrydosWalletHomePage> {
  int _selectedIndex = 0;
  int _selectedTransactionIndex = 0; // لحفظ العنصر المختار
  final List<String> _selectedCurrencies = []; // قائمة العملات المختارة للفلترة

  // دالة مساعدة لتوليد نص عنوان المعاملات بناءً على الفلترة
  String get _transactionsTitle {
    if (_selectedCurrencies.isEmpty) {
      return 'All Transactions';
    }
    return '${_selectedCurrencies.join(' & ')} Transactions';
  }

  // دالة مساعدة لبناء عنصر المعاملة مع التعامل مع حالة الاختيار
  Widget _buildTransactionItem(
    int index, {
    required String icon,
    required String directionIcon,
    required String title,
    Color? titleColor,
    required String subtitle,
    Color? subtitleColor,
    required String amount,
    Color? amountColor,
    required String status,
    Color? statusColor,
  }) {
    final bool isSelected = _selectedTransactionIndex == index;
    return TransactionItem(
      icon: icon,
      directionIcon: directionIcon,
      title: title,
      titleColor: titleColor ?? Colors.black87,
      subtitle: subtitle,
      subtitleColor: subtitleColor ?? Colors.grey,
      amount: amount,
      amountColor: amountColor ?? Colors.black,
      status: status,
      statusColor: statusColor ?? Colors.grey,
      isSelected: isSelected,
      onTap: () {
        setState(() {
          _selectedTransactionIndex = index;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SvgPicture.asset(
                    TrydosWalletAssets.rdb,
                    package: TrydosWalletStyles.packageName,
                    height: 30,
                  ),
                  SvgPicture.asset(
                    TrydosWalletAssets.qr,
                    package: TrydosWalletStyles.packageName,
                    height: 35,
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 5, left: 24, right: 24),
              child: Divider(color: Color(0xffD3D3D3)),
            ),

            // Balance Header
            Padding(
              padding: const EdgeInsets.only(left: 24, right: 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Your Total Balance',
                    style: TrydosWalletStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xff1D1D1D),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {},
                    icon: SvgPicture.asset(
                      TrydosWalletAssets.addCurrency,
                      package: TrydosWalletStyles.packageName,
                    ),
                    label: Text(
                      'Add Currency',
                      style: TrydosWalletStyles.bodySmall.copyWith(
                        color: const Color(0xFF388CFF),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Balance Cards
            SizedBox(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  BalanceCard(
                    symbol: '\$',
                    currencyName: 'American Dollars',
                    amount: '1000',
                    currencyCode: 'USD',
                    color: _selectedCurrencies.contains('USD')
                        ? const Color(0xff315391)
                        : const Color(0xFF3C3C3C),
                    isSelected: _selectedCurrencies.contains('USD'),
                    onTap: () {
                      setState(() {
                        if (_selectedCurrencies.contains('USD')) {
                          _selectedCurrencies.remove('USD');
                        } else {
                          _selectedCurrencies.add('USD');
                        }
                      });
                    },
                  ),
                  const SizedBox(width: 5),
                  BalanceCard(
                    flag: '🇸🇾', // Use a flag or icon if available
                    currencyName: 'Syrian Pounds',
                    amount: '1000',
                    currencyCode: 'SYP',
                    color: _selectedCurrencies.contains('SYP')
                        ? const Color(0xff315391)
                        : const Color(0xFF3C3C3C),
                    isSelected: _selectedCurrencies.contains('SYP'),
                    onTap: () {
                      setState(() {
                        if (_selectedCurrencies.contains('SYP')) {
                          _selectedCurrencies.remove('SYP');
                        } else {
                          _selectedCurrencies.add('SYP');
                        }
                      });
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            // Transactions Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _transactionsTitle,
                style: TrydosWalletStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xff1D1D1D),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Transactions List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildTransactionItem(
                    0,
                    icon: TrydosWalletAssets.cashDeposit,
                    directionIcon: TrydosWalletAssets.downArrow,
                    title: 'Cash Deposit',
                    subtitle: '03.March | Jamilya Center Office 20019Rf',
                    amount: '100,000 \$',
                    status: 'Success',
                    amountColor: Color(0xff1D1D1D),
                    titleColor: Color(0xff1D1D1D),
                    statusColor: Color(0xff1D1D1D),
                    subtitleColor: Color(0xff8D8D8D),
                  ),
                  _buildTransactionItem(
                    1,
                    icon: TrydosWalletAssets.cashDeposit,
                    directionIcon: TrydosWalletAssets.downArrow,
                    title: 'Cash Deposit',
                    subtitle: '03.March | Jamilya Center Office 20019Rf',
                    amount: '100,000 \$',
                    status: 'Success',
                    amountColor: Color(0xff1D1D1D),
                    titleColor: Color(0xff1D1D1D),
                    statusColor: Color(0xff1D1D1D),
                    subtitleColor: Color(0xff8D8D8D),
                  ),
                  _buildTransactionItem(
                    2,
                    icon: TrydosWalletAssets.cashWithdrawal,
                    directionIcon: TrydosWalletAssets.upArrow,
                    title: 'Cash Withdrawal',
                    subtitle: '03.March | Jamilya Center Office 20019Rf',
                    amount: '100,000 \$',
                    status: 'Success',
                    amountColor: Color(0xff1D1D1D),
                    titleColor: Color(0xff1D1D1D),
                    statusColor: Color(0xff1D1D1D),
                    subtitleColor: Color(0xff8D8D8D),
                  ),
                  _buildTransactionItem(
                    3,
                    icon: TrydosWalletAssets.orderInvoice,
                    directionIcon: TrydosWalletAssets.upArrow,
                    title: 'Order Invoice Payment',
                    subtitle: '03.March | TR200 Order',
                    amount: '-1010 SYP',
                    status: 'Blocked',
                    amountColor: Color(0xff8D8D8D),
                    titleColor: Color(0xff8D8D8D),
                    statusColor: Color(0xff8D8D8D),
                    subtitleColor: Color(0xff8D8D8D),
                  ),
                  _buildTransactionItem(
                    4,
                    icon: TrydosWalletAssets.refundOrder,
                    directionIcon: TrydosWalletAssets.downArrow,
                    title: 'Refund Order',
                    subtitle: '03.March | TR200 Order Refund',
                    amount: '410 \$',
                    status: '',
                    amountColor: Color(0xff1D1D1D),
                    titleColor: Color(0xff1D1D1D),
                    statusColor: Color(0xff1D1D1D),
                    subtitleColor: Color(0xff8D8D8D),
                  ),
                  _buildTransactionItem(
                    5,
                    icon: TrydosWalletAssets.refundOrder,
                    directionIcon: TrydosWalletAssets.downArrow,
                    title: 'Refund Order',
                    subtitle: '03.March | TR200 Order Refund',
                    amount: '9 \$',
                    status: '',
                    amountColor: Color(0xff1D1D1D),
                    titleColor: Color(0xff1D1D1D),
                    statusColor: Color(0xff1D1D1D),
                    subtitleColor: Color(0xff8D8D8D),
                  ),
                  _buildTransactionItem(
                    6,
                    icon: TrydosWalletAssets.refundOrder,
                    directionIcon: TrydosWalletAssets.downArrow,
                    title: 'Refund Order',
                    subtitle: '03.March | TR200 Order Refund',
                    amount: '15,20 \$',
                    status: '',
                    amountColor: Color(0xff1D1D1D),
                    titleColor: Color(0xff1D1D1D),
                    statusColor: Color(0xff1D1D1D),
                    subtitleColor: Color(0xff8D8D8D),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFFF5F5F5),
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Colors.black87,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: TrydosWalletStyles.bodySmall.copyWith(fontSize: 10),
        unselectedLabelStyle: TrydosWalletStyles.bodySmall.copyWith(
          fontSize: 10,
        ),
        items: [
          BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: SvgPicture.asset(
                TrydosWalletAssets.home,
                package: TrydosWalletStyles.packageName,
                colorFilter: ColorFilter.mode(
                  _selectedIndex == 0 ? Color(0xff404040) : Color(0xffA2A0A0),
                  BlendMode.srcIn,
                ),
              ),
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: SvgPicture.asset(
                TrydosWalletAssets.transactions,
                package: TrydosWalletStyles.packageName,
                colorFilter: ColorFilter.mode(
                  _selectedIndex == 1 ? Color(0xff404040) : Color(0xffA2A0A0),
                  BlendMode.srcIn,
                ),
              ),
            ),
            label: 'Transactions',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: SvgPicture.asset(
                TrydosWalletAssets.addresses,
                package: TrydosWalletStyles.packageName,
                colorFilter: ColorFilter.mode(
                  _selectedIndex == 2 ? Color(0xff404040) : Color(0xffA2A0A0),
                  BlendMode.srcIn,
                ),
              ),
            ),
            label: 'Addresses',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: SvgPicture.asset(
                TrydosWalletAssets.setting,
                package: TrydosWalletStyles.packageName,
                colorFilter: ColorFilter.mode(
                  _selectedIndex == 3 ? Color(0xff404040) : Color(0xffA2A0A0),
                  BlendMode.srcIn,
                ),
              ),
            ),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

/// ويدجت لعرض بطاقة الرصيد.
class BalanceCard extends StatelessWidget {
  final String? symbol;
  final String? flag;
  final String currencyName;
  final String amount;
  final String currencyCode;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const BalanceCard({
    super.key,
    this.symbol,
    this.flag,
    required this.currencyName,
    required this.amount,
    required this.currencyCode,
    required this.color,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        padding: const EdgeInsets.only(top: 10, left: 15, right: 15),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              // ignore: deprecated_member_use
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (symbol != null)
                  Text(
                    symbol!,
                    style: TrydosWalletStyles.headlineMedium.copyWith(
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  )
                else if (flag != null)
                  Text(flag!, style: const TextStyle(fontSize: 24)),
                const SizedBox(height: 4),
                Text(
                  currencyName,
                  style: TrydosWalletStyles.bodySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    amount,
                    style: TrydosWalletStyles.amountText.copyWith(
                      color: Colors.white,
                      fontSize: 25,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    currencyCode,
                    style: TrydosWalletStyles.bodySmall.copyWith(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ويدجت لعرض معاملة واحدة في القائمة.
class TransactionItem extends StatelessWidget {
  final String icon;
  final String directionIcon;
  final String title;
  final Color titleColor;
  final String subtitle;
  final Color subtitleColor;
  final String amount;
  final Color amountColor;
  final String status;
  final Color statusColor;
  final bool isSelected;
  final VoidCallback? onTap;

  const TransactionItem({
    super.key,
    required this.icon,
    required this.directionIcon,
    required this.title,
    this.titleColor = Colors.black87,
    required this.subtitle,
    this.subtitleColor = Colors.grey,
    required this.amount,
    this.amountColor = Colors.black,
    required this.status,
    this.statusColor = Colors.grey,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 5),
        padding: const EdgeInsets.only(right: 14, bottom: 8, left: 10, top: 8),
        decoration: BoxDecoration(
          border: isSelected
              ? Border.all(color: const Color(0xFFD3D3D3))
              : Border.all(color: Colors.transparent),
          color: const Color(0xFFFCFCFC),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            // Left: Icon and Arrow
            Column(
              children: [
                SvgPicture.asset(icon, package: TrydosWalletStyles.packageName),
                const SizedBox(height: 4),
                SvgPicture.asset(
                  directionIcon,
                  package: TrydosWalletStyles.packageName,
                ),
              ],
            ),
            const SizedBox(width: 10),

            // Middle: Title and Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TrydosWalletStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TrydosWalletStyles.bodySmall.copyWith(
                      color: subtitleColor,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            // Right: Amount and Status
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  amount,
                  style: TrydosWalletStyles.bodyMedium.copyWith(
                    fontWeight: isSelected ? FontWeight.bold : null,
                    color: amountColor,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  status,
                  style: TrydosWalletStyles.bodySmall.copyWith(
                    color: statusColor,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
