export class Attribute {
  value: string;
  viewValue: string;
}

export type AsyncApiRefs = {
  currentGeneration: AsyncApiRef
  generations: AsyncApiRef[]
}

export type AsyncApiRef = {
  id: string
  info: any
  version: string
  url: string
}

