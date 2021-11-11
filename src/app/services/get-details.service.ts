import {Injectable} from '@angular/core';
import {HttpClient} from '@angular/common/http';
import {Observable} from 'rxjs';
import {map} from 'rxjs/operators';
import * as YAML from 'yaml';

@Injectable({ providedIn: 'root' })
export class GetDetailsService {

  constructor(
    private http: HttpClient) { }

  getAsyncApiByUrl(url: string): Observable<any> {
    return this.http.get(url).pipe(
      map((result: any) => YAML.parse(atob(result.content)))
    )
  }
}
