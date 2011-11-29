//
//  TADirectionsRequestStatus.h
//  TollAvoider
//
//  Created by David Foster on 11/29/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

typedef enum {
    TADirectionsNotRequested,
    TADirectionsRequesting,
    TADirectionsError,
    TADirectionsZeroResults,
    TADirectionsOK,
} TADirectionsRequestStatus;
