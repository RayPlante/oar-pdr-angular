import { NgModule }     from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';

import { ToolbarModule } from 'primeng/toolbar';
import { ToastrModule } from 'ngx-toastr';

import { CollapseModule } from '../collapseDirective/collapse.module';
import { SharedModule } from '../../shared/shared.module';
import { AuthorComponent } from './author.component';
import { AuthorPopupComponent } from './author-popup/author-popup.component';
import { AuthorService } from './author.service';
import { ButtonModule } from 'primeng/button';
import { AuthorListComponent } from './author-list/author-list.component';
import { AuthorEditComponent } from './author-edit/author-edit.component';
import { TextEditModule } from '../../text-edit/text-edit.module';
import { DragDropModule } from '@angular/cdk/drag-drop';

/**
 * module that provide support for rendering and managing a resource's 
 * author list
 */
@NgModule({
    imports: [
        CommonModule,
        FormsModule,
        SharedModule,
        ToolbarModule,
        CollapseModule,
        ButtonModule,
        TextEditModule,
        DragDropModule,
        ToastrModule.forRoot()
    ],
    declarations: [
        AuthorComponent, AuthorPopupComponent, AuthorListComponent, AuthorEditComponent
    ],
    providers: [
        AuthorService
    ],
    exports: [
        AuthorComponent, AuthorPopupComponent, AuthorListComponent, AuthorEditComponent
    ]
})
export class AuthorModule { }

export {
    AuthorComponent, AuthorPopupComponent, AuthorService, AuthorListComponent, AuthorEditComponent
};

    
