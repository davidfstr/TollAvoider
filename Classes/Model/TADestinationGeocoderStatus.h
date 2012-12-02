//
//  TADestinationGeocoderStatus.h
//  TollAvoider
//
//  Created by David Foster on 11/17/11.
//  Copyright (c) 2011 Seabalt Solutions, LLC. All rights reserved.
//

typedef enum {
    TAGeocoderNotGeocoding,
    TAGeocoderGeocoding,
    TAGeocoderGeocodeAmbiguous,
    TAGeocoderGeocodeNoMatch,
    TAGeocoderGeocodeFailed,
    TAGeocoderGeocodeComplete,
} TADestinationGeocoderStatus;
