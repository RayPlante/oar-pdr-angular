import { APP_INITIALIZER } from '@angular/core';
import { HttpClientTestingModule, HttpTestingController } from '@angular/common/http/testing';
import { TestBed } from '@angular/core/testing';
import { HttpClient } from '@angular/common/http';

import { ServiceModule, RPAService } from './service.module';

describe('ServiceModule', () => {
    let service: RPAService;
    let httpMock: HttpTestingController;

    beforeEach(() => {
        TestBed.configureTestingModule({
            imports: [ HttpClientTestingModule, ServiceModule ],
        });
        service = TestBed.inject(RPAService);
        httpMock = TestBed.inject(HttpTestingController);
        let req = httpMock.expectOne('assets/config.json');
        req.flush({
            baseUrl: "http://goober.net/"
        });
        
        TestBed.inject(APP_INITIALIZER);
    });

    it('baseURL is correctly set', () => {
        expect(service.baseUrl).toEqual("http://goober.net/");
    });

});

