import {Component, ElementRef, OnDestroy, Input, OnInit, OnChanges, SimpleChanges} from '@angular/core';
// @ts-ignore
import AsyncApiStandalone from '@asyncapi/react-component/browser/standalone';
import {OAuthService} from "angular-oauth2-oidc";

@Component({
  selector: 'app-asyncapi-react',
  template: `
    <div id="asyncapi-doc"></div>
  `,
  styleUrls: ['./asyncapi-react.component.css']
})
export class AsyncapiReactComponent implements OnDestroy, OnInit, OnChanges {
  constructor(private element: ElementRef,
              private oauthService: OAuthService) {}

  @Input()
  schema: any;

  ngOnInit() {
    this.renderSchema()
  }

  ngOnChanges(changes: SimpleChanges): void {
    this.renderSchema()
  }

  ngOnDestroy(): void {
    this.element.nativeElement.querySelector('#asyncapi-doc').remove();
  }

  private renderSchema() {
    const schema = JSON.stringify(this.schema); // AsyncAPI specification, fetched or pasted.
    let authHeader = {}
    if (this.oauthService.hasValidAccessToken()) {
      authHeader = {
        Authorization: "Bearer " + this.oauthService.getAccessToken(),
      };
    }
    const config = {
      parserOptions: {
        resolve: {
          file: false,                    // Don't resolve local file references
          http: {
            timeout: 2000,                // 2 second timeout
            withCredentials: false,       // for GitGub this must be disabled, because 'Access-Control-Allow-Credentials' header is not included in responses
            headers: {
              ...authHeader,
              Accept: "application/vnd.github.v3.raw, application/json, application/yaml" // application/vnd.github.v3.raw required in order to resolve from https://api.github.com
            }
          }
        }
      }
    }; // Configuration for component. This same as for normal React component
    const container = this.element.nativeElement.querySelector('#asyncapi-doc');
    AsyncApiStandalone.render({ schema, config }, container);
  }
}
