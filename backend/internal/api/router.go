package api

import "github.com/gin-gonic/gin"

func Register(router *gin.Engine) {

	router.POST("/chat", Chat)

}
