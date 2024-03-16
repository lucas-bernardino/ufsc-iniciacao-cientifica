import { Entity, PrimaryGeneratedColumn, Column } from "typeorm";

@Entity()
export class Microphone {
  @PrimaryGeneratedColumn()
  id: number;

  @Column("text")
  decibels: number;
}
