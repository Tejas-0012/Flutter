export type RestaurantStackParamList = {
  Restaurant: { restaurantId: string };
  DeliveryTracking: {
    restaurantCoords: { latitude: number; longitude: number };
  };
};