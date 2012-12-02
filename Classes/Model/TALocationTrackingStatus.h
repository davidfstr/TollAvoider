//
//  TALocationTrackingStatus.h
//  TollAvoider
//
//  Created by David Foster on 11/18/11.
//  Copyright (c) 2011 Seabalt Solutions, LLC. All rights reserved.
//

typedef enum {
    TALocationIdle,
    TALocationIsolating,
    TALocationErrorDenied,
    TALocationErrorOther,
    TALocationFound,
} TALocationTrackingStatus;
