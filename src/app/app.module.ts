import { HttpClientModule } from '@angular/common/http';
import { CUSTOM_ELEMENTS_SCHEMA, NgModule } from '@angular/core';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';
import { MatCardModule } from '@angular/material/card';
import { MatToolbarModule } from '@angular/material/toolbar';
import { BrowserModule } from '@angular/platform-browser';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';

import { AppRoutingModule } from './app-routing.module';
import { AppComponent } from './app.component';
import { AsyncapiDetailsComponent } from './directory/asyncapi-details/asyncapi-details.component';
import { AsyncapiReactComponent } from './directory/asyncapi-details/asyncapi-react/asyncapi-react.component';
import { MetaInfoComponent } from './directory/asyncapi-details/meta-info/meta-info.component';
import { RawContentComponent } from './directory/asyncapi-details/raw-content/raw-content.component';
import { DirectoryComponent } from './directory/directory.component';
import { MaterialModule } from './material/material.module';
import { OAuthModule } from "angular-oauth2-oidc";

@NgModule({
  declarations: [
    AppComponent,
    DirectoryComponent,
    AsyncapiDetailsComponent,
    MetaInfoComponent,
    AsyncapiReactComponent,
    RawContentComponent
  ],
  imports: [
    BrowserModule,
    FormsModule,
    AppRoutingModule,
    MatCardModule,
    AppRoutingModule,
    HttpClientModule,
    MaterialModule,
    BrowserAnimationsModule,
    ReactiveFormsModule,
    MatToolbarModule,
    OAuthModule.forRoot({
      resourceServer: {
        sendAccessToken: true,
        allowedUrls: ['https://api.github.com']
      }
    })
  ],
  providers: [],
  bootstrap: [AppComponent],
  schemas: [CUSTOM_ELEMENTS_SCHEMA]
})
export class AppModule { }
