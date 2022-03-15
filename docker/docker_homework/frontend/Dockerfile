FROM node:12-alpine as base
WORKDIR /node
COPY package.json .
# COPY . .
# COPY . /node
RUN npm install
# RUN npm install -g npm@8.5.4
COPY . /node
RUN npm run build

# FROM node:12-alpine
# COPY --from=base /node /node
# WORKDIR /node
# # EXPOSE 3000
# CMD [ "npm", "start" ]

# docker rm -vf $(docker ps -aq) && docker rmi -f $(docker images -aq)

FROM nginx:1.21.6-alpine
COPY ./nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=base /node/build /usr/share/nginx/html





