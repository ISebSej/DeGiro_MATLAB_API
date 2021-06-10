classdef DeGiroAPI < handle
    % Handle to ensure that degiro.method() saves the value to itsself
    %% Login variables
    properties
        test_test
        test_test1
        login_cookie
        session_id
        client_info
        portfolio
        total_portfolio
    end
    %% URLs for connection
    properties(Constant)
        URL_debug = "https://enzqvacsojnb0zc.m.pipedream.net";
        
        URL_login           = 'https://trader.degiro.nl/login/secure/login';
        URL_config          = 'https://trader.degiro.nl/login/secure/config';
        URL_logout          = 'https://trader.degiro.nl/trading/secure/logout';
        URL_client_info     = 'https://trader.degiro.nl/pa/secure/client';
        URL_get_stocks      = 'https://trader.degiro.nl/products_s/secure/v5/stocks';
        URL_product_search  = 'https://trader.degiro.nl/product_search/secure/v5/products/lookup';
        URL_product_info    = 'https://trader.degiro.nl/product_search/secure/v5/products/info';
        URL_transactions    = 'https://trader.degiro.nl/reporting/secure/v4/transactions';
        URL_orders          = 'https://trader.degiro.nl/reporting/secure/v4/order-history';
        URL_place_order     = 'https://trader.degiro.nl/trading/secure/v5/checkOrder';
        URL_order           = 'https://trader.degiro.nl/trading/secure/v5/order/';
        URL_data            = 'https://trader.degiro.nl/trading/secure/v5/update/';
        URL_price_data      = 'https://charting.vwdservices.com/hchart/v1/deGiro/data.js';
    end
    methods
        %% init
        function hObj = DeGiroAPI()
            if nargin == 0
                
            end
        end
        
        %% Basic functionality
        function hObj = Login (hObj, username_in, password_in)
            % prepare payload
            login_payload = struct("username", username_in, "password", password_in);
            
            % prepare header of http request
            contenttypeField    = matlab.net.http.HeaderField("Content-Type","text/plain");     %make sure it is text/plain and not application/json. This causes issues.
            useragentField      = matlab.net.http.HeaderField("user-agent","");
            acceptencodingField = matlab.net.http.HeaderField("accept-encoding","");
            dateField           = matlab.net.http.HeaderField("date","");
            
            %construct request
            r = matlab.net.http.RequestMessage(...
                'POST',...
                [ contenttypeField acceptencodingField dateField useragentField ], ...
                jsonencode(login_payload)...
                );
            
            % Send request to login api
            login_resp = send(r, hObj.URL_login);
            
            %set session_id and JSESSIONID cookie
            hObj.session_id = login_resp.Body.Data.sessionId;
            setCookieFields = login_resp.getFields('Set-Cookie');
            
            hObj.login_cookie = matlab.net.http.Cookie(...
                "JSESSIONID",...
                erase(setCookieFields.Value, "JSESSIONID=")...
                );
            
            % Get Client information
            hObj.GetClientInfo();
            
            
        end
        function hObj = Logout (hObj)
            warning("Just wait for timeout, not sure how to fix this yet");
        end
        
        %% Access User information
        function hObj = GetClientInfo(hObj)
            
            % prepare header of http request
            useragentField      = matlab.net.http.HeaderField("user-agent","");
            acceptencodingField = matlab.net.http.HeaderField("accept-encoding","");
            dateField           = matlab.net.http.HeaderField("date","");
            
            %construct GET request
            r = matlab.net.http.RequestMessage(...
                'GET',...
                [ acceptencodingField dateField useragentField ]...
                );
            
            % Send request to login api
            uri = hObj.URL_client_info + "?sessionId=" + hObj.session_id;
            login_resp = send(r, uri);
            hObj.test_test = login_resp;
            % Save client information - NOTE: Stores pretty much all
            % personal info
            hObj.client_info = login_resp.Body.Data.data;
        end
        function hObj = GetClientToken(hObj)
            
            % prepare header of http request
            useragentField      = matlab.net.http.HeaderField("user-agent","");
            acceptencodingField = matlab.net.http.HeaderField("accept-encoding","");
            dateField           = matlab.net.http.HeaderField("date","");
            cookieField         = matlab.net.http.field.CookieField(hObj.login_cookie);
            
            %construct GET request
            r = matlab.net.http.RequestMessage(...
                'GET',...
                [ cookieField acceptencodingField dateField useragentField ]...
                );
            
            % Send request to login api
            uri = hObj.URL_config;
            
            login_resp = send(r, uri);
            string(login_resp)
        end
        
        %% Get User Portfolio
        
        function hObj = GetPortfolio(hObj)
            
            % prepare header of http request
            useragentField      = matlab.net.http.HeaderField("user-agent","");
            acceptencodingField = matlab.net.http.HeaderField("accept-encoding","");
            dateField           = matlab.net.http.HeaderField("date","");
            %cookieField         = matlab.net.http.field.CookieField(hObj.login_cookie);
            
            %construct GET request
            r = matlab.net.http.RequestMessage(...
                'GET',...
                [ acceptencodingField dateField useragentField]);
            
            intAccount = int2str(hObj.client_info.intAccount);
            % Send request to login api
            uri = strcat( hObj.URL_data, intAccount) + ";jsessionid=" + hObj.session_id + "?portfolio=0&totalPortfolio=0&intAccount=" +intAccount + "&sessionId=" + hObj.session_id;
            % for some reason I need to use str instead of +
            
            resp = send(r, uri);
            
            % Process portfolio summary
            
            hObj.total_portfolio = resp.Body.Data.totalPortfolio.value;
            
            % Process portfolio 
            
            allAssets = [];
            activeAssets = [];
            inactiveAssets = [];
            cashAsset = [];
            for j = 1:length(resp.Body.Data.portfolio.value)
                
                tmpportfolio = resp.Body.Data.portfolio.value(j);
                
                valueList= [];
                for i = 1:15
                    struct = tmpportfolio.value(i);
                    
                    if i == 1 || i == 2
                        value = string(struct{1}.value);
                    elseif      i == 6
                        value = 0;
                    elseif      i == 7
                        value = struct{1}.value.EUR;
                    elseif      i == 8
                        value = struct{1}.value.EUR;
                    else
                        value = struct{1}.value;
                    end
                    
                    valueList = [valueList value];
                end
                
                asset.id                        = valueList(1);
                asset.positionType              = valueList(2);
                asset.size                      = valueList(3);
                asset.price                     = valueList(4);
                asset.value                     = valueList(5);
                asset.plBase                    = valueList(7);
                asset.todayPlBase               = valueList(8);
                asset.portfolioValueCorrection  = valueList(9);
                asset.breakEvenPrice            = valueList(10);
                asset.averageFxRate             = valueList(11);
                asset.realizedProductPl         = valueList(12);
                asset.realizedFxPl              = valueList(13);
                asset.todayRealizedProductPl    = valueList(14);
                asset.todayRealizedFxPl         = valueList(15);
                
                allAssets = [allAssets; asset] ;
                
                switch asset.positionType
                    case "CASH"
                        cashAsset = [cashAsset asset];
                    case "PRODUCT"
                        if str2num(asset.size) == 0
                            inactiveAssets = [inactiveAssets asset];
                        else
                            activeAssets = [activeAssets asset];
                        end
                end                
            end
            
            hObj.portfolio.all = allAssets;
            hObj.portfolio.active = activeAssets;
            hObj.portfolio.inactive = inactiveAssets;
            hObj.portfolio.cash = cashAsset;
        end
        
        function nameList = searchProduct(hObj, idList)
            nameList = '';
        end
    end
end
