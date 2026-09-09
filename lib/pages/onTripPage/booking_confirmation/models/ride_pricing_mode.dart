enum RidePricingMode {
  fixedFare,
  riderOffer;

  static RidePricingMode fromService(Map service) {
    return service['enable_bidding'] == true
        ? RidePricingMode.riderOffer
        : RidePricingMode.fixedFare;
  }
}
