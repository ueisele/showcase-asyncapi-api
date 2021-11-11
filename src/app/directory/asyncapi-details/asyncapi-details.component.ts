import {ChangeDetectorRef, Component, OnInit} from '@angular/core';
import '@asyncapi/web-component/lib/asyncapi-web-component';
import {GetDetailsService} from '../../services/get-details.service';
import {Location} from '@angular/common';
import {AsyncApiRef, AsyncApiRefs} from '../../models/attribute';
import {Router} from '@angular/router';

@Component({
  selector: 'app-asyncapi-details',
  templateUrl: './asyncapi-details.component.html',
  styleUrls: ['./asyncapi-details.component.css']
})

export class AsyncapiDetailsComponent implements OnInit {
  asyncApiRefs: AsyncApiRefs;
  schema: any;

  constructor(private getDetailsService: GetDetailsService,
              private location: Location,
              private router: Router,
              private cd: ChangeDetectorRef) {}

  ngOnInit() {
    const state: any = this.location.getState();
    if (! ('currentGeneration' in state) || !('generations' in state)) {
      this.router.navigate(['directory']);
      return;
    }

    this.asyncApiRefs = state;
    this.getDetailsService.getAsyncApiByUrl(this.asyncApiRefs.currentGeneration.url)
      .subscribe(apiDefinition => {
        this.schema = apiDefinition;
      });
  }

  onChangeVersion(newVersion: AsyncApiRef) {
    this.asyncApiRefs.currentGeneration = newVersion;
    this.getDetailsService.getAsyncApiByUrl(this.asyncApiRefs.currentGeneration.url)
      .subscribe(apiDefinition => {
        this.schema = apiDefinition;
        this.cd.detectChanges();
      });
  }
}
