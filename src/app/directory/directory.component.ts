import {Component, OnInit, ViewChild} from '@angular/core';
import { Router } from '@angular/router';
import {UpdateDirectoryService} from '../services/update-directory.service';
import {Observable} from 'rxjs';
import {FormControl} from '@angular/forms';
import {map, startWith} from 'rxjs/operators';
import {AsyncApiRefs, Attribute} from '../models/attribute';
import {MatPaginator, PageEvent} from '@angular/material/paginator';
import {OAuthService} from "angular-oauth2-oidc";

@Component({
  selector: 'app-directory',
  templateUrl: './directory.component.html',
  styleUrls: ['./directory.component.css']
})

export class DirectoryComponent implements OnInit {
  @ViewChild(MatPaginator) paginator!: MatPaginator;

  apis: AsyncApiRefs[] = [];
  displayedApis: AsyncApiRefs[] = [];
  optionsArtifactId: string[] = [];
  optionsTeam: string[] = [];
  searchValue = '';
  pageSize = 4;
  pageEvent!: PageEvent;
  pageLength = 0;

  filteredOptions!: Observable<string[]>;
  myControl = new FormControl();
  attributes: Attribute[] = [
    {value: 'artifactId-0', viewValue: 'ArtifactID'},
    {value: 'team-1', viewValue: 'Team'}
  ];
  selectedAttribute: string = this.attributes[0].viewValue;

  constructor(private router: Router,
              private updateDirectoryService: UpdateDirectoryService,
              private oauthService: OAuthService) {

  }

  ngOnInit(): void {
    this.updateDirectoryService.getAsyncApiSummary().subscribe(returnedApis => {
      this.apis = returnedApis;
      this.pageLength = returnedApis.length;
      this.displayedApis = returnedApis;
      this.optionsArtifactId = returnedApis.map(a => a.currentGeneration.id);
      this.optionsTeam = [...new Set(returnedApis.reduce((result: string[], value) => {
        if ('contact' in value.currentGeneration.info && 'x-team-name' in value.currentGeneration.info.contact) {
          result.push(value.currentGeneration.info.contact['x-team-name'].toString());
        }
        return result;
      }, []))];
    });

    this.filteredOptions = this.myControl.valueChanges
      .pipe(
        startWith(''),
        map(value => this._filter(value))
      );
  }

  onGetDetails(asyncApiRefs: AsyncApiRefs) {
    this.router.navigateByUrl('directory/details', {state: asyncApiRefs});
  }

  onSearchEnter(searchValue: string) {
    searchValue = searchValue.toLowerCase();

    if (this.selectedAttribute === this.attributes[0].viewValue) {
      this.displayedApis = this.apis.filter(str => str.currentGeneration.id.toString().toLowerCase().includes(searchValue));
    } else if (this.selectedAttribute === this.attributes[1].viewValue) {
      this.displayedApis = this.apis.filter((value) => {
        if ('contact' in value.currentGeneration.info && 'x-team-name' in value.currentGeneration.info.contact) {
          if (value.currentGeneration.info.contact['x-team-name'].toString().toLowerCase().includes(searchValue)) {
            return true;
          }
        }
        return false;
      });
    }
  }

  onChangeFilter(attribute: Attribute) {
    this.selectedAttribute = attribute.viewValue;
    this.displayedApis = this.apis;
    this.myControl.setValue('');
  }

  private _filter(value: string): string[] {
    const filterValue = value.toLowerCase();

    if (this.selectedAttribute === this.attributes[0].viewValue) {
      return this.optionsArtifactId.filter(option => option.toLowerCase().includes(filterValue));
    } else if (this.selectedAttribute === this.attributes[1].viewValue) {
      return this.optionsTeam.filter(option => option.toLowerCase().includes(filterValue));
    }
    return [];
  }

  login() {
    this.oauthService.initLoginFlow()
  }
}
