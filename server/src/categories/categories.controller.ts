import { Controller, Get } from '@nestjs/common';
import { CATEGORIES } from './categories';

@Controller('categories')
export class CategoriesController {
  @Get()
  list() {
    return CATEGORIES;
  }
}
