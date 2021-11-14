import { Component } from '@angular/core';
import {AuthConfig, OAuthService} from "angular-oauth2-oidc";

export const authConfig: AuthConfig = {

  oidc: false,
  loginUrl: 'https://github.com/login/oauth/authorize',
  tokenEndpoint: 'https://githuboauth-asyncapidirectory.herokuapp.com/access_token',

  redirectUri: window.location.origin + '/index.html',

  clientId: '78d8a114e9817dace68f',

  scope: 'repo',

  responseType: 'code',
  disablePKCE: true,

  requireHttps: false
}

@Component({
  selector: 'app-root',
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.css']
})
export class AppComponent {
  title = 'AsyncAPI Directory';

  constructor(private oauthService: OAuthService) {
    oauthService.configure(authConfig);
    oauthService.tryLoginCodeFlow()
  }
}
