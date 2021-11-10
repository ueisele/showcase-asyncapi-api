import {Injectable} from '@angular/core';
import {HttpClient} from '@angular/common/http';
import {forkJoin, Observable} from 'rxjs';
import {parse} from 'yamljs';
import {map} from "rxjs/operators";
import {AsyncApiRefs} from "../models/attribute";

@Injectable({ providedIn: 'root' })
export class UpdateDirectoryService {

  private gitHubUrl = 'https://api.github.com/repos/ueisele/showcase-asyncapi-api/git/trees/main'
  private pathValidator = /^asyncapi\/.*\.(yaml|yml)$/;

  constructor(
    private http: HttpClient) { }

  getAsyncApiSummary(): Observable<AsyncApiRefs[]> {
    return new Observable<AsyncApiRefs[]>(observer => {
      this.http.get(`${this.gitHubUrl}?recursive=1`).pipe(
        map((result: any) => result.tree.filter(ref => ref.type === "blob" && this.pathValidator.test(ref.path))),
      ).subscribe((res: any[]) => {
        const requests = res.map(ref => this.http.get(ref.url).pipe(
          map((result: any) => parse(atob(result.content))),
          map((json: any) => {return{
            id: json.id.toString(),
            info: json.info,
            version: json.info.version.toString(),
            url: ref.url,
          }})
        ));
        forkJoin(requests).subscribe(all => {
          const apiRefMap = new Map<string,AsyncApiRefs>();
          all.forEach(api => {
            if (!apiRefMap.has(api.id)) {
              apiRefMap.set(api.id, {
                currentGeneration: api,
                generations: [api]
              })
            } else if (apiRefMap.get(api.id).currentGeneration.version < api.version) {
              // version of api to add is larger
              apiRefMap.get(api.id).currentGeneration = api
              apiRefMap.get(api.id).generations.push(api)
            } else {
              // version of api to add is smaller
              apiRefMap.get(api.id).generations.push(api)
            }
          })
          apiRefMap.forEach(apiRef => apiRef.generations
            .sort((left, right) => left.version.localeCompare(right.version)))
          observer.next(Array.from(apiRefMap.values()))
          observer.complete()
        })
      })
    })
  }

}
