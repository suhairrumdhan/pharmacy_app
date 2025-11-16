import 'package:get/get.dart';
import '../models/sales_model.dart';

class SalesController extends GetxController {
  var sales = <Sale>[].obs;
  var todaySales = <Sale>[].obs;
  var isLoading = false.obs;
  var salesSummary = SalesSummary(
    todaySales: 0,
    weeklySales: 0,
    monthlySales: 0,
    totalTransactions: 0,
    averageSale: 0,
  ).obs;

  @override
  void onInit() {
    super.onInit();
    loadSales();
    loadTodaySales();
    calculateSummary();
  }

  void loadSales() {
    // TODO: جلب المبيعات من Firestore
    isLoading(true);

    // بيانات تجريبية
    sales.value = [
      Sale(
        id: '1',
        customerName: 'أحمد محمد',
        customerPhone: '0512345678',
        items: [
          SaleItem(
            medicineId: 'med1',
            medicineName: 'بانادول',
            quantity: 2,
            price: 15.0,
            total: 30.0,
          ),
        ],
        totalAmount: 30.0,
        discount: 0,
        tax: 1.5,
        finalAmount: 31.5,
        saleDate: DateTime.now(),
        paymentMethod: 'cash',
        status: 'completed',
      ),
      Sale(
        id: '2',
        customerName: 'فاطمة علي',
        customerPhone: '0554321000',
        items: [
          SaleItem(
            medicineId: 'med2',
            medicineName: 'فيتامين سي',
            quantity: 1,
            price: 45.0,
            total: 45.0,
          ),
        ],
        totalAmount: 45.0,
        discount: 5.0,
        tax: 2.0,
        finalAmount: 42.0,
        saleDate: DateTime.now().subtract(const Duration(days: 1)),
        paymentMethod: 'card',
        status: 'completed',
      ),
    ];

    isLoading(false);
  }

  void loadTodaySales() {
    final today = DateTime.now();
    todaySales.value = sales.where((sale) =>
    sale.saleDate.year == today.year &&
        sale.saleDate.month == today.month &&
        sale.saleDate.day == today.day
    ).toList();
  }

  void calculateSummary() {
    final today = DateTime.now();
    final todaySalesList = sales.where((sale) =>
    sale.saleDate.year == today.year &&
        sale.saleDate.month == today.month &&
        sale.saleDate.day == today.day
    ).toList();

    final weeklySalesList = sales.where((sale) =>
        sale.saleDate.isAfter(today.subtract(const Duration(days: 7)))
    ).toList();

    final monthlySalesList = sales.where((sale) =>
    sale.saleDate.year == today.year &&
        sale.saleDate.month == today.month
    ).toList();

    salesSummary.value = SalesSummary(
      todaySales: todaySalesList.fold(0, (sum, sale) => sum + sale.finalAmount),
      weeklySales: weeklySalesList.fold(0, (sum, sale) => sum + sale.finalAmount),
      monthlySales: monthlySalesList.fold(0, (sum, sale) => sum + sale.finalAmount),
      totalTransactions: sales.length,
      averageSale: sales.isEmpty
          ? 0.0
          : sales.fold(0.0, (sum, sale) => sum + sale.finalAmount) / sales.length,
    );

  }

  void addSale(Sale newSale) {
    sales.add(newSale);
    calculateSummary();
    // TODO: حفظ في Firestore
  }

  void deleteSale(String saleId) {
    sales.removeWhere((sale) => sale.id == saleId);
    calculateSummary();
    // TODO: حذف من Firestore
  }
}