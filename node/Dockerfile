
FROM node:16
WORKDIR /app
COPY . .
RUN npm install
COPY . .
EXPOSE 3000
ENV MONGO_URI="mongodb://localhost:27017/mydb"
CMD ["node", "nodeapp.js"]