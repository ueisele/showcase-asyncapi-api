import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { AsyncapiDetailsComponent } from './directory/asyncapi-details/asyncapi-details.component';
import { DirectoryComponent } from './directory/directory.component';

const routes: Routes = [
  { path: '', component: DirectoryComponent },
  { path: 'directory', component: DirectoryComponent },
  { path: 'directory/details', component: AsyncapiDetailsComponent }
];

@NgModule({
  imports: [RouterModule.forRoot(routes)],
  exports: [RouterModule]
})
export class AppRoutingModule { }
