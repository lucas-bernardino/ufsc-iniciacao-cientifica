import express, { NextFunction, Request, Response } from "express";
import dotenv from "dotenv";
import "reflect-metadata";
import { AppDataSource } from "./db-config";
import { Microphone } from "./entity/MicrophoneModel";

import { StatusCodes } from "http-status-codes";
import { MicrophoneSchema } from "./entity/MicrophoneSchema";

const app = express();
dotenv.config(); //Reads .env file and makes it accessible via process.env

app.use(express.json());

AppDataSource.initialize()
  .then(() => {
    console.log("Database successfully initialized");
  })
  .catch((error) => console.log(error));

app.get("/test", (req: Request, res: Response, next: NextFunction) => {
  res.send("hi");
});

app.post("/send", async (req: Request, res: Response, next: NextFunction) => {
  try {
    const microphone = await AppDataSource.getRepository(Microphone).create(
      req.body,
    );
    console.log("Req body:", req.body);
    const results =
      await AppDataSource.getRepository(Microphone).save(microphone);
    console.log("Results: ", results);
    return res.status(StatusCodes.CREATED).json({ results });
  } catch (error) {
    console.log(error);
    return res.status(StatusCodes.INTERNAL_SERVER_ERROR).json({ error: error });
  }
});

app.get("/recieve_all", async (req: Request, res: Response) => {
  try {
    const allData = await AppDataSource.getRepository(Microphone).find();
    return res.status(StatusCodes.OK).json({ allData });
  } catch (error) {}
});

app.listen(process.env.PORT, () => {
  console.log(`Server is running at ${process.env.PORT}`);
});
