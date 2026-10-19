enum RidePricingMode {
  fixedFare,
  riderOffer;

  static RidePricingMode fromService(Map service) {
    final pricingMode = service['pricing_mode']?.toString().toLowerCase();
    if (pricingMode == 'bidding') return RidePricingMode.riderOffer;
    if (pricingMode == 'fixed') return RidePricingMode.fixedFare;
    return service['enable_bidding'] == true
        ? RidePricingMode.riderOffer
        : RidePricingMode.fixedFare;
  }
}
