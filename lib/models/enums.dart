enum DeliveryOption { pickup, delivery, discuss }
enum TenderStatus { open, closed, extended }
enum ListingStatus { available, sold, expired }

String deliveryOptionToString(DeliveryOption option) {
  switch (option) {
    case DeliveryOption.pickup:
      return 'pickup';
    case DeliveryOption.delivery:
      return 'delivery';
    case DeliveryOption.discuss:
      return 'discuss';
  }
}

DeliveryOption stringToDeliveryOption(String str) {
  switch (str.toLowerCase()) {
    case 'pickup':
      return DeliveryOption.pickup;
    case 'delivery':
      return DeliveryOption.delivery;
    case 'discuss':
      return DeliveryOption.discuss;
    default:
      return DeliveryOption.pickup;
  }
}

String tenderStatusToString(TenderStatus status) {
  switch (status) {
    case TenderStatus.open:
      return 'open';
    case TenderStatus.closed:
      return 'closed';
    case TenderStatus.extended:
      return 'extended';
  }
}

TenderStatus stringToTenderStatus(String str) {
  switch (str.toLowerCase()) {
    case 'open':
      return TenderStatus.open;
    case 'closed':
      return TenderStatus.closed;
    case 'extended':
      return TenderStatus.extended;
    default:
      return TenderStatus.open;
  }
}

String listingStatusToString(ListingStatus status) {
  switch (status) {
    case ListingStatus.available:
      return 'available';
    case ListingStatus.sold:
      return 'sold';
    case ListingStatus.expired:
      return 'expired';
  }
}

ListingStatus stringToListingStatus(String str) {
  switch (str.toLowerCase()) {
    case 'available':
      return ListingStatus.available;
    case 'sold':
      return ListingStatus.sold;
    case 'expired':
      return ListingStatus.expired;
    default:
      return ListingStatus.available;
  }
}
